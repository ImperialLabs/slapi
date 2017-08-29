# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'

# Adapter Class
# Its main functions are to:
#  1. Load Chat Adapter
#     - Find adapter in config
#     - Pull adapter container and load
class Bot
  GREEN = '#229954'
  YELLOW = '#F7DC6F'
  RED = '#A93226'

  def intialize(settings)
    @settings = settings
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    @brain = Brain.new(settings)
    @adapter = Adapter.new(settings)
    @plugins = Plugin.new(settings)
    @adapter_info = @adapter.info
  end

  def listener(data)
    case data.command
    when 'ping', 'Ping'
      @logger.debug("Slapi: #{data.user} requested ping")
      ping(data)
    when 'help', 'Help'
      @logger.debug("Slapi: #{data.user} requested help")
      help(data)
    when 'reload', 'Reload'
      @logger.debug("Slapi: #{data.user} requested plugin reload")
      @plugins.reload
    else
      @logger.debug("Slapi: #{data.user} request forwarded to check against plugins")
      plugin(data)
    end
  end

  def run
    @adapter.run
  end

  def shutdown
    @adapter.shutdown
    @brain.shutdown
  end

  def ping(data)
    attachment = {
      title: 'Bot Check',
      text: 'PONG',
      color: GREEN
    }
    @adapter.formatted(data.channel, attachment)
  end

  def help(data)
    plugin = Plugin.lookup(data)
    help_success(data, plugin) if help_verify(data)
    help_fail(data) unless help_verify(data)
    @plugins.help_list
  end

  def help_success(data, plugin)
    unless data.command.include?('help ') || @settings.help['level'] == 2
      help_text = "Please use `@#{@bot_name} help plugin_name` for specific info"
    end
    attachment = {
      pretext: help_text,
      fallback: 'Your help has arrived!',
      title: 'Help List',
      text: @plugins.help_list(plugin),
      color: YELLOW
    }
    @adapter.formatted(data.channel, attachment)
  end

  def help_fail(data)
    attachment = {
      title: 'Help Error',
      fallback: 'Plugins or Commands not Found!',
      text: "Sorry <@#{data.user}>, I did not find any help commands or plugins to list",
      color: RED
    }
    @adapter.formatted(data.channel, attachment)
  end

  def plugin(data)
    plugin = Plugin.lookup(data) # TODO: Need to create Plugin module helper
    @plugins.exec(plugin) if @plugins.verify(plugin)
  end
end
