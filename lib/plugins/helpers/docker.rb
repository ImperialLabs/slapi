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

  def bind_set(filename = nil, script = nil)
    @binds = []
    @logger.debug("Plugin: #{@name}: Setting Binds")
    @binds.push("#{Dir.pwd}/scripts/#{filename}:/scripts/#{filename}") if script
    @binds.push("#{Dir.pwd}/config/plugins/#{@name}.yml:#{@config['plugin']['mount_config']}") if @config['plugin']['mount_config']
  end

  def image_set
    repo = @type == 'script' ? @lang_settings[:image] : @config['plugin']['config']['Image']
    @image = Docker::Image.create(fromImage: repo)
    @image_info = @image.info
  end

  def manage_set
    clear_existing_container(@name)
    ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
    @container_hash['Env'] = ["BOT_URL=#{ip}:#{@settings.port}"]
    build if @config['plugin']['build']
    image_set unless @config['plugin']['build']
  end

  def build
    file_location = File.expand_path('../' + @settings.plugins['location'] + @name, File.dirname(__FILE__))
    @logger.debug("Plugin: #{@name}: Building from Dockerfile from location - #{file_location}")
    @image = Docker::Image.build_from_dir(file_location)
    @image_info = Docker::Image.get(@image.info['id']).info
    @image.tag(repo: @name, tag: 'latest', force: true)
  end

  def hash_set(filename = nil, script = nil)
    if script
      @container_hash[:image] = @lang_settings[:image]
      @container_hash[:HostConfig][:Binds] = @binds
      @container_hash[:Entrypoint] = "/scripts/#{filename}"
      @container_hash[:Tty] = true
      @container_hash['Labels'] = @config['plugin']['help']
    else
      @container_hash['Entrypoint'] = @image_info['Config']['Entrypoint'] ? @image_info['Config']['Entrypoint'] : @image_info['Config']['Cmd']
      @container_hash['ExposedPorts'] = @image_info['Config']['ExposedPorts'] if @image_info['Config']['ExposedPorts']
      @container_hash['WorkingDir'] = @image_info['Config']['WorkingDir']
      @container_hash['Labels'] = @image_info['Config']['Labels']
      @container_hash[:HostConfig][:Binds] = @binds
      @config['plugin']['config'].each do |key, value|
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
