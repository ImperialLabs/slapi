# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'
require 'docker'
require 'active_support/core_ext/object/blank'

# Docker/Container Helpers
# Its main functions are to provide simplified access to Docker
module Container
  class << self
    def pull(name, container_config, logger)
      repo_info = repo(name, container_config, logger)
      Docker::Image.create(fromImage: "#{repo_info[:name]}:#{repo_info[:tag]}")
      repo_info
    end

    def build(repo_info, config, logger, location = nil)
      if Docker::Image.exist?("#{repo_info[:name]}:#{repo_info[:tag]}") && !config['build_force']
        existing_image("#{repo_info[:name]}:#{repo_info[:tag]}", logger)
      else
        build_image(repo_info[:name], config[:container_config], logger, location)
      end
    end

    def build_image(name, container_config, logger, location)
      file_location = File.expand_path('../' + location + name, File.dirname(__FILE__))
      logger.debug("Container: #{name}: Building from Dockerfile from location - #{file_location}")
      image = container_config['build_stream'].present? ? build_stream(file_location) : Docker::Image.build_from_dir(file_location)
      image_info = Docker::Image.get(image.info['id']).info
      repo_info = repo(name, container_config, logger)
      image.tag(repo: repo_info[:name], tag: repo_info[:tag], force: true)
      { image: image, info: image_info, repo: repo_info }
    end

    def repo(name, container_config, logger, type = nil)
      if container_config[:Image].present?
        repo_name = container_config[:Image][/[^:]+/]
        repo_tag = container_config[:Image].include?(':') ? container_config[Image].sub("#{repo_name}:", '') : 'latest'
      elsif type == 'script'
        script_repo = script_image(name, logger, container_config[:language])
      else
        repo_name = name
        repo_tag = 'latest'
      end
      type == 'script' ? script_repo : { name: repo_name, tag: repo_tag }
    end

    def create(container_config)
      Docker::Container.create(container_config)
    end

    def script_image(name, logger, lang = nil)
      case lang
      when 'ruby', 'rb'
        { file_type: '.rb', name: 'slapi/ruby', tag: 'latest' }
      when 'python', 'py'
        { file_type: '.py', name: 'slapi/python', tag: 'latest' }
      when 'node', 'nodejs', 'javascript', 'js'
        { file_type: '.js', name: 'slapi/nodejs', tag: 'latest' }
      when 'bash', 'shell', 'sh'
        { file_type: '.sh', name: 'slapi/base', tag: 'latest' }
      else
        logger.warn("Container: #{name}: Language not set in config, defaulting to shell/bash")
        { file_type: '.sh', name: 'slapi/base', tag: 'latest' }
      end
    end

    def existing_image(repo, logger)
      logger.debug("Container: #{repo}: Image already exists, using existing image")
      Docker::Image.get(repo)
    end

    def config_merge(image, container_config, config = {})
      container_config[:Entrypoint] = image.info['Config']['Entrypoint'] ? image.info['Config']['Entrypoint'] : image.info['Config']['Cmd']
      container_config[:ExposedPorts] = image.info['Config']['ExposedPorts'] if image.info.dig('Config', 'ExposedPorts')
      container_config[:WorkingDir] = image.info['Config']['WorkingDir']
      if container_config[:Labels].blank?
        container_config[:Labels] = image.info['Config']['Labels']
      else
        container_config[:Labels].merge!(image.info['Config']['Labels']) if image.info.dig('Config', 'Labels')
      end
      container_config[:Labels].merge(config[:help]) unless config[:help].blank?
      container_config
    end

    def start(name, passive = nil, plugin_config = {})
      container = Docker::Container.get(name) unless passive
      container = Container.create(plugin_config[:config]) if passive
      response = container.tap(&:start) unless passive
      response = container.tap(&:start).attach(tty: true, stdout: true, logs: true) if passive
      response
    end

    def exec(name, exec_array)
      container = Docker::Container.get(name)
      container.exec(exec_array, wait: 20)
    end

    def build_stream(file_location)
      image = Docker::Image.build_from_dir(file_location) do |v|
        log = JSON.parse(v)
        $stdout.puts log['stream'] if log.key?('stream')
      end
      image
    end

    def cleanup(name, logger)
      begin
        container = Docker::Container.get(name)
      rescue
        logger.debug("Container: #{name}: No exisiting container")
        return false
      end
      logger.debug("Container: #{name}: existing container removed") if container
      container&.delete(force: true) if container
    end
  end
end
