# frozen_string_literal: true
require 'httparty'
require 'logger'
require 'json'
require 'yaml'
require 'docker'
require 'sterile'
require_relative 'helpers/docker'
require_relative 'helpers/exec'

# Plugin class will represent an individual plugin.
# It will check the metadata of the type of plugins to make decisions.
# Its two main functions are to:
#  1. Load the configuration of the specific plugin and load anything needed for that type.
#  2. Execute the command properly based on the type
class Plugin
  attr_reader :help

  def initialize(file, settings)
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    @name = File.basename(file, '.*')
    @config = YAML.load_file(file)
    @help = ''
    @container = nil
    @container_hash = { name: @name, HostConfig: {} }
    @api_info = {}
    load
    @logger.debug("Plugin: #{@name}: Succesfully Loaded")
  end

  # Keeping DRY, all repetive load tasks go here.
  def load_docker(filename = nil)
    clear_existing_container(@name)
    case @config['plugin']['type']
    when 'script'
      @image = Docker::Image.create(fromImage: @lang_settings[:image])
      bind_set(filename, true)
      hash_set(@image, filename, true)
    when 'container'
      @image = Docker::Image.create(fromImage: @config['plugin']['config']['Image'])
      bind_set
      hash_set(@image)
    end
  end

  def hash_set(image = nil, filename = nil, script = nil)
    if script
      @container_hash[:image] = @lang_settings[:image]
      @container_hash[:HostConfig][:Binds] = @binds
      @container_hash[:Entrypoint] = "/scripts/#{filename}"
      @container_hash[:Tty] = true
      @container_hash['Labels'] = @config['plugin']['help']
    else
      @container_hash['Entrypoint'] = image.info['Config']['Entrypoint']
      @container_hash['WorkingDir'] = image.info['Config']['WorkingDir']
      @container_hash['Labels'] = image.info['Config']['Labels']
      @container_hash[:HostConfig][:Binds] = @binds
      @config['plugin']['config'].each do |key, value|
        @container_hash[key] = value
      end
    end
  end

  def write_script(filename)
    File.open("scripts/#{filename}", 'w') do |file|
      file.write(@config['plugin']['write'])
    end
    File.chmod(0o777, "scripts/#{filename}")
  end

  def load_active
    @container = Docker::Container.create(@container_hash)
    @container.start
  end

  def load_api
    @headers = {
      'Content-Type' => @config['plugin']['api']['content_type']
      # 'Authorization' => @config['plugin']['api']['auth']
    }
    # @api_url = Magic here to decided in API plugin is local or external
    @api_info = HTTParty.get("#{@api_url}/info", headers: @headers)
  end

  # Load the plugin configuration.
  # The plugin type is the important switch here.
  def load
    case @config['plugin']['type']
    when 'script'
      @lang_settings = lang_settings(@config['plugin']['language'])
      filename = "#{@name}#{@lang_settings[:file_type]}"
      load_docker(filename)
      write_script(filename)
    when 'container'
      # load the docker container set in the config
      load_docker
      load_active if @config['plugin']['listen_type'] == 'active'
    when 'api'
      load_api
    else
      @logger.error("Plugin: #{@name}: unknown plugin type configured #{@config['plugin']['type']}")
      raise "Plugin: #{@name}: only 'script', 'container', and 'api' are known"
    end
    help_load
  end

  # Build out help commands for users to query in chat
  def help_load
    if @container_hash['Labels']
      @help_hash = @container_hash['Labels']
    elsif @api_info.key? :Help
      @help_hash = @api_info['help']
    elsif @config['plugin']['help']
      @help_hash = @config['plugin']['help']
    end

    @logger.info("#{@name}: #{@help_hash ? 'Help list being built' : 'No help or labels found'}")

    @help_hash&.each do |label, desc|
      @help += '    ' + label + ' : ' + desc + "\n"
    end
  end

  # Execute the command sent from chat
  #
  # @param string data_from_chat
  # @return string representing response to be displayed
  def exec(chat_data = nil)
    # based on some meta information like the type then execute the proper way
    # Strip an incorrection coded qoutes to UTF8 ones
    data_from_chat = sterilize(chat_data)
    # Split chat data after @bot plugin into args to pass into plugin.
    # Split args based on qoutes, args are based on spaces unless in qoutes
    chat_text_array = data_from_chat.text.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
    exec_data = data_type(data_from_chat, chat_text_array)
    case @config['plugin']['type']
    when 'script', 'container'
      case @config['plugin']['listen_type']
      when 'passive'
        exec_passive(exec_data)
      when 'active'
        @container.exec([exec_data])
      end
    when 'api'
      exec_api(data_from_chat, chat_text_array)
    end
  end

  def exec_passive(exec_data)
    @container_hash[:Cmd] = exec_data
    @container = Docker::Container.create(@container_hash)
    @container.tap(&:start).attach(tty: true)
    response = @container.logs(stdout: true)
    @container.delete(force: true)
    response
  end

  def exec_api(data_from_chat, chat_text_array)
    payload = {
      chat:
        {
          user: data_from_chat['user'],
          channel: data_from_chat['channel'],
          type: data_from_chat['type'],
          timestamp: data_from_chat['ts']
        },
      command: {
        # text without username or plugin name
        data: chat_text_array.drop(2)
      }
    }
    HTTParty.post(@config['plugin']['api']['url'], body: payload, headers: @headers)
    # else ?
    # Error log and chat?
    # Since it will only make it to this level if the bot was invoked
    # then may it is appropriate to state that the bot does not understand?.
  end

  private :exec_passive, :exec_api

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

  # Shutdown procedures for container and script plugins
  def shutdown(name)
    clear_existing_container(name)
  end
end
