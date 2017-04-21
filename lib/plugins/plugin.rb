# frozen_string_literal: true
require 'httparty'
require 'logger'
require 'json'
require 'yaml'
require 'docker'
require 'sterile'
require 'socket'
require 'active_support/core_ext/object/blank'
require_relative 'helpers/docker'
require_relative 'helpers/exec'

# Plugin class will represent an individual plugin.
# It will check the metadata of the type of plugins to make decisions.
# Its two main functions are to:
#  1. Load the configuration of the specific plugin and load anything needed for that type.
#  2. Execute the command properly based on the type
class Plugin
  attr_reader :help, :type
  attr_accessor :config

  def initialize(file, settings)
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    @settings = settings
    @name = File.basename(file, '.*')
    @config = YAML.load_file(file)
    @help = ''
    @type = @config['plugin']['type']
    @headers = {}
    @headers = @config['plugin']['api_config']['headers'] if @config.dig('plugin', 'api_config', 'headers')
    @listen_type = @config['plugin']['listen_type']
    @managed = @type == 'api' ? false : true
    @managed = @config['plugin']['managed'] if @config.dig('plugin', 'managed')
    @container = nil
    @container_hash = { name: @name, HostConfig: {} }
    @api_info = {}
    Docker.options = {
      read_timeout: 180
    }
    load
    @logger.debug("Plugin: #{@name}: Succesfully Loaded")
  end

  # Execute the command sent from chat
  #
  # @param string data_from_chat
  # @return string representing response to be displayed
  def exec(client_id, chat_data = nil)
    # based on some meta information like the type then execute the proper way
    # Strip an incorrection coded qoutes to UTF8 ones
    data_from_chat = sterilize(chat_data)
    # Split chat data after @bot plugin into args to pass into plugin.
    # Split args based on qoutes, args are based on spaces unless in qoutes
    chat_text_array = data_from_chat.text.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
    exec_data = data_type(data_from_chat, chat_text_array, client_id)
    case @type
    when 'script', 'container'
      case @listen_type
      when 'passive'
        exec_passive(exec_data)
      when 'active'
        @logger.debug("Plugin: #{@name}: Sending '#{exec_data}' to active plugin")
        exec_array = @config['plugin']['command'].split(' ')
        exec_array.push(exec_data)
        response = @container.exec(exec_array, wait: 20)
        response[0][0].to_s
      end
    when 'api'
      exec_api(data_from_chat, chat_text_array)
    end
  end

  private

  # Load the plugin configuration.
  # The plugin type is the important switch here.
  def load
    case @type
    when 'script'
      @lang_settings = lang_settings(@config['plugin']['language'])
      filename = "#{@name}#{@lang_settings[:file_type]}"
      load_docker(filename)
      write_script(filename)
    when 'container'
      # load the docker container set in the config
      load_passive unless @listen_type == 'active'
      load_active if @listen_type == 'active'
    when 'api'
      load_api
    else
      @logger.error("Plugin: #{@name}: unknown plugin type configured #{@type}")
      raise "Plugin: #{@name}: only 'script', 'container', and 'api' are known"
    end
    help_load
  end

  def load_active
    if @managed
      @logger.debug("Plugin: #{@name}: Is set to managed and being loaded by Slapi")
      load_docker
      start_managed
    else
      attach_active
    end
  end

  def load_passive
    load_docker
  end

  def url_set
    @container_info = Docker::Container.get(@name).info
    # Complete url for plugin endpoint, configured in config/plugin/$name.yml
    if @managed
      # Builds URL based on Container Settings
      port = @container_info['NetworkSettings']['Ports'].keys[0].to_s
      container_ip = @container_info['NetworkSettings']['IPAddress'].to_s
      local_ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address

      # Determine if running via DIND/Compose Config or if running local
      compose_bot = local_ip.rpartition('.')[0] == container_ip.rpartition('.')[0]
      @logger.debug(compose_bot ? "Plugin: #{@name}: running inside DIND" : "Plugin: #{@name}: running on local machine")

      # If Compose, set docker network ip. If, local use localhost
      ip = compose_bot ? "http://#{container_ip}" : "http://#{local_ip}"
      @api_url = ip + ':' + port.chomp('/tcp')
    else
      @api_url = @config['plugin']['api_config']['url']
    end
    @logger.debug("Plugin: #{@name}: URL is set to #{@api_url}")
  end

  def load_api
    if @managed
      @logger.debug("Plugin: #{@name}: Is set to managed and being loaded by Slapi")
      load_docker
      start_managed
      url_set
    end

    @logger.debug("Plugin: #{@name}: Loaded, getting info from API Endpoint")

    @response = OpenStruct.new(body: nil)

    while @response.body.blank?
      begin
        @response = HTTParty.get("#{@api_url}/info")
      rescue StandardError
        sleep(1)
      end
    end

    if @response.success?
      @api_info = JSON.parse(@response.body)
    else
      @logger.error("Plugin: #{@name}: No info endpoint or error with endpoint")
    end
  end

  # Keeping DRY, all repetive load tasks go here.
  def load_docker(filename = nil)
    @logger.debug("Plugin: #{@name}: Set as #{@type} plugin, loading plugin")
    case @type
    when 'script'
      clear_existing_container(@name)
      image_set # Helper
      bind_set(filename, true) # Helper
      hash_set(filename, true) # Helper
    when 'container', 'api'
      manage_set if @managed # Helper
      image_set unless @managed # Helper
      bind_set # Helper
      hash_set # Helper
    end
  end

  def write_script(filename)
    @logger.debug("Plugin: #{@name}: Writing script for plugin")
    File.open("scripts/#{filename}", 'w') do |file|
      file.write(@config['plugin']['write'])
    end
    File.chmod(0o777, "scripts/#{filename}")
  end

  def attach_active
    @logger.debug("Plugin: #{@name}: Attaching Non-Managed plugin")
    @container = Docker::Container.get(name)
    @container_info = Docker::Container.get(@name).info
  end

  def start_managed
    @logger.debug("Plugin: #{@name}: Starting as Managed Plugin")
    @container = Docker::Container.create(@container_hash)
    @container.tap(&:start)
  end

  # Build out help commands for users to query in chat
  def help_load
    if @api_info['help']
      @help_hash = @api_info['help']
    elsif @container_hash['Labels']
      @help_hash = @container_hash['Labels']
    elsif @config['plugin']['help']
      @help_hash = @config['plugin']['help']
    end

    @logger.info("Plugin: #{@name}: #{@help_hash ? 'Help list being built' : 'No help or labels found'}")

    @help_hash&.each do |label, desc|
      @help += '    ' + label + ' : ' + desc + "\n"
    end
  end

  def exec_passive(exec_data)
    @logger.debug("Plugin: #{@name}: creating and sending '#{exec_data}' to passive plugin")
    @container_hash[:Cmd] = exec_data
    @container = Docker::Container.create(@container_hash)

    @container.tap do |container|
      container.start
      container.attach(tty: true)
      container.wait(20)
    end

    response = @container.logs(stdout: true)
    @container.delete(force: true)
    response
  end

  def exec_api(data_from_chat, chat_text_array)
    response = api_response(data_from_chat, chat_text_array)

    if response.success?
      response.body unless response.body.blank?
      response.code if @settings.environment == 'test'
    else
      @logger.error("Plugin: #{@name}: returned code of #{response.code}")
      return "Error: Received code #{response.code}"
    end
  end

  def api_response(data_from_chat, chat_text_array)
    payload_build = {
      chat:
        {
          type: data_from_chat['type'],
          channel: data_from_chat['channel'],
          user: data_from_chat['user'],
          text: data_from_chat['text'],
          timestamp: data_from_chat['ts'],
          team: data_from_chat['team']
        },
      # Data without botname and plugin stripped leaving args
      command: chat_text_array.drop(2)
    }

    # Set Payload Type based on Content Type
    payload = @headers.dig('Content-Type') ? content_set(payload_build) : payload_build

    @exec_url = @api_url + @config['plugin']['api_config']['endpoint']
    @logger.debug("Plugin: #{@name}: Exec URL is set to #{@exec_url}")
    @logger.debug("Plugin: #{@name}: Exec '#{chat_text_array.drop(2)}' being sent via API")
    auth = @config.dig('plugin', 'api_config', 'basic_auth') ? @config['plugin']['api_config']['basic_auth'] : nil
    HTTParty.post(@exec_url, basic_auth: auth, body: payload, headers: @headers) if auth
    HTTParty.post(@exec_url, body: payload, headers: @headers) unless auth
  end

  def content_set(payload_build)
    @headers['Content-Type'] == 'application/json' ? payload_build.to_json : payload_build
  end
end
