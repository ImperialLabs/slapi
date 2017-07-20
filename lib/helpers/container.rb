# frozen_string_literal: true

require 'socket'
require 'logger'
require 'json'
require 'yaml'
require 'docker'
require 'active_support/core_ext/hash/indifferent_access'

# Docker/Container Helpers
# Its main functions are to:
#  1.
module Container
  def pull(name, config)
    repo(name, config)
    image = Docker::Image.create(fromImage: repo)
    image_info = image.info
  end

  def build(name, config)
    if Docker::Image.exist?(name) && !config['build_force']
      existing_image
    else
      build_image
    end
  end

  def build_image(name, config, logger)
    file_location = File.expand_path('../' + settings.plugins['location'] + name, File.dirname(__FILE__))
    logger.debug("Plugin: #{name}: Building from Dockerfile from location - #{file_location}")
    image = if config['build_stream'] ? build_stream(file_location) : Docker::Image.build_from_dir(file_location)
    image_info = Docker::Image.get(image.info['id']).info
    repo_info = repo(name, config, logger)
    image.tag(repo: repo_info[:name], tag: repo_info[:tag], force: true)
    { image: image, info: image_info, repo: repo_info }
  end

  def repo(name, config, logger)
    if config.dig('config', 'Image')
      repo_name = config['config']['Image'][/[^:]+/]
      repo_tag = config['config']['Image'].include?(':') ? config['config']['Image'].sub("#{repo_name}:", '') : 'latest'
    elsif config['type'] == 'script'
      repo = script_image(name, logger, config[:language])
    else
      repo_name = name
      repo_tag = 'latest'
    end
    return if config['type'] == 'script' ? repo : { name: repo_name, tag: repo_tag }
  end

  def script_image(name, logger, lang = nil)
    case lang
    when 'ruby', 'rb'
      { file_type: '.rb', name: 'slapi/ruby', tag:'latest' }
    when 'python', 'py'
      { file_type: '.py', name: 'slapi/python', tag:'latest' }
    when 'node', 'nodejs', 'javascript', 'js'
      { file_type: '.js', name: 'slapi/nodejs', tag:'latest' }
    when 'bash', 'shell', 'sh'
      { file_type: '.sh', name: 'slapi/base', tag:'latest' }
    else
      logger.warn("Container: #{name}: Language not set in config, defaulting to shell/bash")
      { file_type: '.sh', name: 'slapi/base', tag:'latest' }
    end
  end

  def existing_image(name, logger)
    logger.debug("Container: #{name}: Image already exists, using existing image")
    Docker::Image.get(name)
  end

  def binds
    binds = []
    binds.push("#{Dir.pwd}/scripts/#{filename}:/scripts/#{filename}") if @config['type'] == 'script'
    binds.push("#{Dir.pwd}/config/plugins/#{@name}.yml:#{@config['mount_config']}") if @config['mount_config']
  end

  def container_config(config, container_config)
    config.each do |key, value|
      if value.is_a?(Array)
        value.each do |v|
          container_config[key] << v
        end
      else
        container_config[key] = value
      end
    end
    container_config
  end

  def build_stream(file_location)
    image = Docker::Image.build_from_dir(file_location) do |v|
      log = JSON.parse(v)
      $stdout.puts log['stream'] if log.key?('stream')
    end
    image
  end

  def cleanup(name)
    begin
      container = Docker::Container.get(name)
    rescue => e
      @logger.debug("Container: #{@name}: No exisiting container")
      return false
    end
    @logger.debug("Container: #{@name}: existing container removed") if container
    container&.delete(force: true) if container
  end
end
