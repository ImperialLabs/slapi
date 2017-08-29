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
require_relative 'helpers/network'
require_relative 'plugin_api'
require_relative 'plugin_container'

# Plugin class will represent an individual plugin.
# It will check the metadata of the type of plugins to make decisions.
# Its two main functions are to:
#  1. Load the configuration of the specific plugin and load anything needed for that type.
#  2. Execute the command properly based on the type
class Plugin
  attr_reader :help, :type
  attr_accessor :config

  def initialize(file, dynamic_port, settings)
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    @settings = settings
    @name = File.basename(file, '.*')
    config = YAML.load_file(file)
    @config = config['plugin']
    @headers = {}
    @headers = @config['api_config']['headers'] if @config.dig('plugin', 'api_config', 'headers')
    @config['exposed_port'] = dynamic_port if @config['exposed_port'].blank?
    @config['listen_type'] = 'passive' if @config['listen_type'].blank?
    @managed = @config['type'] == 'api' ? false : true
    @managed = @config['managed'] if @config['managed']
    @container = nil
    @container_hash = {
      name: @name,
      Tty: true,
      HostConfig: {},
      RestartPolicy: {
        Name: 'on-failure',
        MaximumRetryCount: 2
      }
    }
    @api_info = {}
    Docker.options[:read_timeout] = 200
    Docker.options[:write_timeout] = 200
    validate
    @network = Network.new
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
    case @config['type']
    when 'script', 'container'
      case @config['listen_type']
      when 'passive'
        exec_passive(exec_data)
      when 'active'
        @logger.debug("Plugin: #{@name}: Sending '#{exec_data}' to active plugin")
        exec_array = @config['command'].split(' ')
        exec_array.push(exec_data)
        response = @container.exec(exec_array, wait: 20)
        response[0][0].to_s
      end
    when 'api'
      exec_api(data_from_chat, chat_text_array)
    end
  end

  private

  # Check plugin config for required configuration based on type
  def validate
    raise "[ERROR] Plugin: #{@name}: No type set! Type is required for all plugins" unless @config['type']
    case @config['type']
    when 'container', 'docker'
      raise "[ERROR] Plugin: #{@name}: No Image Set! in config" unless @config.dig('config', 'Image')
    when 'api'
      raise "[ERROR] Plugin: #{@name}: No Endpoint Set! in api_config" unless @config.dig('api_config', 'endpoint')
    end
  end

  # Load the plugin configuration.
  # The plugin type is the important switch here.
  def load
    @bot_ip = @network.bot_ip(@config) # Helper to set bot_ip
    case @config['type']
    when 'script'
      @lang_settings = lang_settings(@config['language'])
      filename = "#{@name}#{@lang_settings[:file_type]}"
      load_docker(filename)
      write_script(filename)
    when 'container', 'docker'
      # load the docker container set in the config
      load_passive unless @config['listen_type'] == 'active'
      load_active if @config['listen_type'] == 'active'
    when 'api'
      load_api
    else
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
    # Complete url for plugin endpoint, configured in config/plugin/$name.yml
    @api_url = "http://#{@plugin_ip}:#{@config['exposed_port']}" if @managed
    @api_url = @config['api_config']['url'] unless @managed
    @logger.debug("Plugin: #{@name}: URL is set to #{@api_url}")
  end

  def load_api
    managed_api if @managed
    @logger.debug("Plugin: #{@name}: Loaded, getting info from API Endpoint")
    api_info(0)
    @config['description'] = @api_info['description'] unless @api_info['description'].blank?
  end

  def api_info(retry_count)
    response = OpenStruct.new(body: nil)

    while retry_count < 5
      begin
        response = HTTParty.get("#{@api_url}/info", timeout: 10)
        if response.success? && !response.body.blank?
          @api_info = JSON.parse(response.body)
          break
        end
      rescue StandardError
        sleep(1)
        retry_count += 1
        @logger.error("Plugin: #{@name}: No info endpoint or no data") if retry_count >= 5
      end
    end
  end

  def managed_api
    @logger.debug("Plugin: #{@name}: Is set to managed and being loaded by Slapi")
    load_docker
    start_managed
    @plugin_ip = @network.plugin_ip(@logger, @config, @name)
    url_set
  end

  # Keeping DRY, all repetive load tasks go here.
  def load_docker(filename = nil)
    @logger.debug("Plugin: #{@name}: Set as #{@config['type']} plugin, loading plugin")
    case @config['type']
    when 'script'
      clear_existing_container(@name)
      image_set # Helper
      bind_set(filename) # Helper
      hash_set(filename) # Helper
    when 'container', 'api'
      manage_set # Helper
      bind_set # Helper
      hash_set # Helper
      if @config['app_port'].blank? && !@container_hash[:ExposedPorts].blank?
        container_port = @container_hash[:ExposedPorts].keys[0].to_s
        @config['app_port'] = container_port.chomp('/tcp')
      end
      @container_hash.merge!(@network.expose(@config)) if @container_hash[:ExposedPorts] # Helper
    end
  end

  def write_script(filename)
    @logger.debug("Plugin: #{@name}: Writing script for plugin")
    File.open("scripts/#{filename}", 'w') do |file|
      file.write(@config['write'])
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
    if @api_info.key?('help')
      help_hash = @api_info['help']
    elsif @container_hash[:Labels]
      @config['description'] = @container_hash[:Labels]['description'] if @container_hash.dig(:Labels, 'description')
      help_hash = @container_hash[:Labels]
      help_hash.delete('description')
    else
      help_hash = ''
    end

    @logger.info("Plugin: #{@name}: #{help_hash ? 'Help list being built' : 'No help or labels found'}")

    help_array = []
    help_hash.each { |label, desc| help_array.push("   #{label} : #{desc}\n") } unless help_hash.blank?
    @help = help_array.join
  end
end
