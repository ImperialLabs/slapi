# frozen_string_literal: true

require 'httparty'
require 'logger'
require 'json'
require 'yaml'
require 'docker'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'
require_relative '../modules/container'
require_relative '../modules/exec'
require_relative '../modules/network'
require_relative '../modules/config'

# Slapin class will represent an individual plugin.
# It will check the metadata of the type of plugins to make decisions.
# Its two main functions are to:
#  1. Load the configuration of the specific plugin and load anything needed for that type.
#  2. Execute the command properly based on the type
class Plugin
  attr_reader :help, :type
  attr_accessor :plugin_config

  def initialize(file, dynamic_port, settings)
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    @settings = settings
    @name = "slapin_#{File.basename(file, '.*')}"
    @type = plugin_config.type
    @passive = plugin_config.listen_type == 'active' ? false : true
    config = YAML.load_file(file).with_indifferent_access
    plugin_config = config.plugin.with_indifferent_access
    plugin_config[:app_port] = dynamic_port if @plugin_config.app_port.blank?
    plugin_config[:managed] = @type == 'api' ? false : true if @plugin_config.managed.blank?
    @plugin_config = default_builder(plugin_config) if plugin_config.managed?
    load
    @logger.debug("Plugin: #{@name}: Succesfully Loaded")
  end

  def default_builder(plugin_config)
    plugin_config[:config] = Config.merge(plugin_config[:config], default_config)
    plugin_config[:config] = Config.merge(plugin_config[:config], mount_config(plugin_config.mount_config)) if plugin_config.mount_config

    case @type
    when 'script'
      filetype = Container.script_image(@name, @logger, plugin_config.language)
      plugin_config[:config] = Config.merge(plugin_config[:config], default_script(filetype))
    when 'container', 'docker'
      plugin_config[:config] = Config.merge(plugin_config[:config], default_container)
    when 'api'
      plugin_config[:config] = Config.merge(plugin_config[:config], default_api)
    end
    plugin_config
  end

  def default_config
    {
      config: {
        name: @name,
        Tty: true,
        Env: ["BOT_URL=#{Network.bot_ip}:#{@settings.port}"]
      }
    }
  end

  def mount_config(mount)
    {
      config: {
        HostConfig: {
          Binds: ["#{Dir.pwd}/config/plugins/#{@name}.yml:#{mount}"]
        }
      }
    }
  end

  def default_script(filetype)
    {
      config: {
        HostConfig: {
          Binds: ["#{Dir.pwd}/scripts/#{@name}.#{filetype}:/scripts/#{@name}.#{filetype}"]
        }
      }
    }
  end

  def default_container
    {
      config: {
        RestartPolicy: {
          Name: 'on-failure',
          MaximumRetryCount: 2
        }
      }
    }
  end

  def default_api
    {
      config: {
        RestartPolicy: {
          Name: 'on-failure',
          MaximumRetryCount: 2
        }
      }
    }
  end

  # Check plugin config for required configuration based on type
  def validate(plugin_config)
    raise "[ERROR] Plugin: #{@name}: No type set! Type is required for all plugins" unless @type
    case @type
    # when 'container', 'docker'
    #   raise "[ERROR] Plugin: #{@name}: No Image Set! in config" unless plugin_config.dig('config', 'Image')
    when 'api'
      raise "[ERROR] Plugin: #{@name}: No Endpoint Set! in api_config" unless plugin_config.dig('api_config', 'endpoint')
    end
  end

  def load
    if @type == 'script'
      filetype = Container.script_image(@name, @logger, @plugin_config.language)
      write_script(filetype)
      @plugin_config.config[:Labels] = @plugin_config['help']
      load_managed
    elsif plugin_config.managed
      @logger.debug("Plugin: #{@name}: Is set to managed and being loaded by Slapi")
      load_managed
    end
    load_api if @type == 'api'
    help_load
  end

  def write_script(filetype)
    @logger.debug("Plugin: #{@name}: Writing script for plugin")
    File.open("scripts/#{@name}.#{filetype}", 'w') do |file|
      file.write(@plugin_config['write'])
    end
    File.chmod(0o777, "scripts/#{@name}.#{filetype}")
  end

  def load_managed
    container_config = @plugin_config.config
    Container.cleanup(container_config[:name])
    Container.pull(container_config[:name], container_config) unless @plugin_config.build
    Container.build(container_config[:name], container_config, @logger) if @plugin_config.build
    build_info = Container.build(container_config[:name], container_config, @logger)
    @plugin_config.config = Container.config_merge(build_info[:image], container_config)
    @plugin_config.config = Container.config_merge(@plugin_config.config, Network.expose(@plugin_config)) if @type == 'api' || @exposed_listener
    Container.create(@plugin_config.config) unless @passive
    Container.start(name) unless @passive
  end

  def load_api
    @plugin_ip = @network.plugin_ip(@name, @plugin_config, @logger)
    @api_url = "http://#{@plugin_ip}:#{@config['exposed_port']}" if @managed
    @api_url = @config['api_config']['url'] unless @managed
    @logger.debug("Plugin: #{@name}: URL is set to #{@api_url}")
    @logger.debug("Plugin: #{@name}: Loaded, getting info from API Endpoint")
    @api_info = {}
    headers = @plugin_config.dig(:api_config, 'headers') ? @plugin_config[:api_config]['headers'] : {}
    @plugin_config[:api_config]['headers'] = headers
    api_info(0)
    @plugin_config[:description] = @api_info['description'] if @api_info['description'].present?
  end

  def api_info(retry_count)
    response = OpenStruct.new(body: nil)
    while retry_count < 5
      begin
        response = HTTParty.get("#{@api_url}/info", headers: @plugin_config[:api_config]['headers'], timeout: 10)
        if response.success? && response.body.present?
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

  def help_load
    if @api_info.key?('help')
      help_hash = @api_info['help']
    elsif @plugin_config.config[:Labels]
      @plugin_config[:description] = @plugin_config.config[:Labels]['description'] if @plugin_config.config.dig(:Labels, 'description')
      help_hash = @plugin_config.config[:Labels]
      help_hash.delete('description')
    else
      help_hash = ''
    end

    @logger.info("Plugin: #{@name}: #{help_hash ? 'Help list being built' : 'No help or labels found'}")

    help_array = []
    help_hash.each { |label, desc| help_array.push("   #{label} : #{desc}\n") } unless help_hash.blank?
    @help = help_array.join
  end

  def exec(client_id, chat_data = nil)
    data_from_chat = Exec.sterilize(chat_data)
    chat_text_array = Exec.split(data_from_chat)
    exec_data = Exec.data_type(data_from_chat, chat_text_array, client_id)

    case @type
    when 'script', 'container'
      Exec.passive(@plugin_config, exec_data, logger) if @passive
      Exec.active(@plugin_config, exec_data, logger) unless @passive
    when 'api'
      Exec.api(@plugin_config, data_from_chat, chat_text_array, @logger)
    end
  end
end
