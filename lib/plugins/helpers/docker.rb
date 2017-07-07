# frozen_string_literal: true

# Docker Helpers for Plugin Class
# Its main functions are to:
#  1. Set Items to be binded/mounted to Plugin Container
#     - Include script if script type
#     - Include plugin config if configured with path to mount/bind
#  2. Set Script Language based on plugin config
#     - Language determines which image is pulled for script exec
class Plugin
  def lang_settings(lang = nil)
    case lang
    when 'ruby', 'rb'
      { file_type: '.rb', image: 'slapi/ruby:latest' }
    when 'python', 'py'
      { file_type: '.py', image: 'slapi/python:latest' }
    when 'node', 'nodejs', 'javascript', 'js'
      { file_type: '.js', image: 'slapi/nodejs:latest' }
    when 'bash', 'shell', 'sh'
      { file_type: '.sh', image: 'slapi/base:latest' }
    else
      @logger.warn("Plugin: #{@name}: Language not set in config, defaulting to shell/bash")
      { file_type: '.sh', image: 'slapi/base:latest' }
    end
  end

  private

  def bind_set(filename = nil)
    @binds = []
    @logger.debug("Plugin: #{@name}: Setting Binds")
    @binds.push("#{Dir.pwd}/scripts/#{filename}:/scripts/#{filename}") if @config['type'] == 'script'
    @binds.push("#{Dir.pwd}/config/plugins/#{@name}.yml:#{@config['mount_config']}") if @config['mount_config']
  end

  def image_set
    repo = @config['type'] == 'script' ? @lang_settings[:image] : @config['config']['Image']
    @image = Docker::Image.create(fromImage: repo)
    @image_info = @image.info
  end

  def manage_set
    clear_existing_container(@name)
    @container_hash['Env'] = ["BOT_URL=#{@bot_ip}:#{@settings.port}"]
    build if @config['build']
    image_set unless @config['build']
  end

  def build
    if Docker::Image.exist?(@name) && !@config['build_force']
      pull_image
    else
      build_image
    end
  end

  def pull_image
    @logger.debug("Plugin: #{@name}: Image already exists and build_force is off, using existing image")
    @image = Docker::Image.get(@name)
    @image_info = @image.info
  end

  def build_image
    file_location = File.expand_path('../' + @settings.plugins['location'] + @name, File.dirname(__FILE__))
    @logger.debug("Plugin: #{@name}: Building from Dockerfile from location - #{file_location}")
    build_stream(file_location) if @config['build_stream']
    @image = Docker::Image.build_from_dir(file_location) unless @config['build_stream']
    @image_info = Docker::Image.get(@image.info['id']).info
    repo_info = repo?
    @image.tag(repo: repo_info[:name], tag: repo_info[:tag], force: true)
  end

  def build_stream(file_location)
    @image = Docker::Image.build_from_dir(file_location) do |v|
      log = JSON.parse(v)
      $stdout.puts log['stream'] if log.key?('stream')
    end
  end

  def repo?
    if @config.dig('config', 'Image')
      repo_name = @config['config']['Image'][/[^:]+/]
      repo_tag = @config['config']['Image'].include?(':') ? @config['config']['Image'].sub("#{repo_name}:", '') : 'latest'
      @config['config']['Image'] = "#{repo_name}:#{repo_tag}"
    else
      repo_name = @name
      repo_tag = 'latest'
    end
    { name: repo_name, tag: repo_tag }
  end

  def hash_set(filename = nil)
    @container_hash[:HostConfig][:Binds] = @binds
    if @config['type'] == 'script'
      script_hash(filename)
    else
      managed_hash
      build_hash
    end
  end

  def script_hash(filename)
    @container_hash[:image] = @lang_settings[:image]
    @container_hash[:Entrypoint] = "/scripts/#{filename}"
    @container_hash[:Labels] = @config['help']
  end

  def managed_hash
    @container_hash[:Entrypoint] = @image_info['Config']['Entrypoint'] ? @image_info['Config']['Entrypoint'] : @image_info['Config']['Cmd']
    @container_hash[:ExposedPorts] = @image_info['Config']['ExposedPorts'] if @image_info.dig('Config', 'ExposedPorts')
    @container_hash[:WorkingDir] = @image_info['Config']['WorkingDir']
    @container_hash[:Labels] = {}
    @container_hash[:Labels].merge!(@image_info['Config']['Labels']) if @image_info.dig('Config', 'Labels')
    @container_hash[:Labels].merge(@config['help']) unless @config['help'].blank?
  end

  def build_hash
    @config['config'].each do |key, value|
      if value.is_a?(Array)
        value.each do |v|
          @container_hash[key] << v
        end
      else
        @container_hash[key] = value
      end
    end
  end

  # Clears out existing container with the name planned to use
  # Avoids this error:
  # Uncaught exception: Conflict. The name "/hello_world" is already in use by container 23ee03db81c93cb7dd9eba206c3a7e.
  #      You have to remove (or rename) that container to be able to reuse that name
  def clear_existing_container(name)
    begin
      container = Docker::Container.get(name)
    rescue StandardError => _error
      @logger.debug("Plugin: #{@name}: No exisiting container")
      return false
    end
    container&.delete(force: true) if container
  end
end
