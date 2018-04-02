# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'
require_relative 'adapter'
require_relative 'brain'
require_relative 'plugins'

# Adapter Class
# Its main functions are to:
#  1. Load Chat Adapter
#     - Find adapter in config
#     - Pull adapter container and load
class Bot
  GREEN = '#229954'
  YELLOW = '#F7DC6F'
  RED = '#A93226'

  def initialize(settings)
    @settings = settings
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    @brain = Brain.new(settings)
    @adapter = Adapter.new(settings)
    @plugins = Plugins.new(settings)
    @adapter_info = @adapter.info(0)
  end

  def listener(data)
    if data[:text].include?('ping')
      @logger.debug("Slapi: #{data[:user]} requested ping")
      ping(data)
    elsif data[:text].include?('help')
      @logger.debug("Slapi: #{data[:user]} requested help")
      help(data)
    elsif data[:text].include?('reload')
      @logger.debug("Slapi: #{data[:user]} requested plugin reload")
      @plugins.reload
    else
      @logger.debug("Slapi: #{data[:user]} request forwarded to check against plugins")
      plugin = lookup(data)
      @plugins.exec(data, @adapter_info['bot']['id'], plugin) if @plugins.verify(plugin)
    end
  end

  def shutdown
    @adapter.shutdown
    @brain.shutdown
    @plugins.shutdown
  end

  private

  def ping(data)
    attachment(data, 'Bot Check', 'PONG', 'PONG', GREEN)
  end

  def help(data)
    plugin = lookup(data)
    unless data[:text].include?('help ') || @settings.help['level'] == 2
      help_text = "Please use `@#{@adapter_info['bot']['name']} help plugin_name` for specific info"
    end
    if plugin
      if @plugins.verify(plugin)
        help_text = @plugins.help_list(plugin)
        color = YELLOW
      else
        help_text = "Sorry <@#{data[:user]}>, I did not find any help commands or plugins to list"
        color = RED
      end
    else
      color = YELLOW
      help = @plugins.help_list
    end
    attachment(data, 'Help List', 'Your help has arrived!', help, color, help_text)
  end

  def attachment(data, title, fallback, text, color = YELLOW, pre_text = nil)
    attachment = {
      pretext: pre_text,
      fallback: fallback,
      title: title,
      text: text,
      color: color
    }
    @adapter.formatted(data[:channel], attachment)
  end

  def lookup(data)
    plugin = nil
    if data[:text].include?(' ')
      data_array = data[:text].split(' ')
      bot_name = data[:text].include?(@adapter_info['bot']['id'])
      plugin = bot_name ? data_array[2] : data_array[1] if data[:text].include?('help')
      plugin = bot_name ? data_array[1] : data_array[0] unless data[:text].include?('help')
    elsif data[:text] == 'help'
      plugin = nil
    elsif !data[:text].include? @adapter_info['bot']['id']
      plugin = data[:text]
    end
    @logger.debug("Slapi: Plugin Requested: #{plugin ? plugin : 'no plugin requested'}")
    plugin
  end
end
