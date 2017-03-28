# frozen_string_literal: true
require 'logger'
require 'json'
require 'yaml'
require 'slack-ruby-client'

# Load Extended Class items
## Plugins
require_relative '../plugins/plugins'

# Base Client for Slapi Class
# Its main functions are to:
#  1. Start the Bot
#     - Set listeners and which helpers to utilize
#  2. Set Slack Client Configuration
#     - Token is read in bot.local.yml/bot.yml and passed from Slapi.rb
#  3. Create Plugins Instance
#     - lib/plugins/plugins.rb
class Bot
  attr_accessor :bot_name
  ## Helpers
  require_relative 'helpers/bot'
  require_relative 'helpers/plugins'

  GREEN = '#229954'
  YELLOW = '#F7DC6F'
  RED = '#A93226'

  def initialize(settings)
    @help_options = settings.help || {}
    @admin_options = settings.admin || {}
    @bot_options = settings.bot || {}

    # Load Plugins
    # Utilizes Library from plugins/plugins
    @plugins = Plugins.new(settings)

    # Setup Realtime Client
    Slack.configure do |config|
      config.token = settings.adapter['token']
      raise 'Missing Slack Token configuration!' unless config.token
    end

    @client = Slack::RealTime::Client.new
    @bot_name = @bot_options['name'] || @client.self.name
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
  end

  def run
    @client.on :hello do
      @logger.info("Slapi: Successfully connected, welcome '#{@client.self.name}' to '#{@client.team.name}'")
    end

    @client.on :message do |data|
      listener(data) if data.user != @client.self.id
    end
    @client.start_async
  end

  def listener(data)
    case data.text
    when /#{bot_prefix(data)}ping/ then
      @logger.debug("Slapi: #{data.user} requested ping")
      ping(data)
    when /#{bot_prefix(data)}help/ then
      @logger.debug("Slapi: #{data.user} requested help")
      get_help(data)
    when /#{bot_prefix(data)}reload/ then
      @logger.debug("Slapi: #{data.user} requested plugin reload")
      reload(data)
    when /#{bot_prefix(data)}/ then
      @logger.debug("Slapi: #{data.user} request forwarded to check against plugins")
      plugin(data)
    end
  end

  private

  def ping(data)
    chat_attachment(
      {
        title: 'Bot Check',
        text: 'PONG',
        color: GREEN
      },
      nil,
      data
    )
  end

  def get_help(data)
    # Remove when doing level 2 help or responding with specific plugin help
    unless data.text.include?('help ') || @help_options['level'] == 2
      help_text = "Please use `@#{@bot_name} help plugin_name` for specific info"
    end
    if help_verify(data)
      chat_attachment(
        {
          pretext: help_text,
          fallback: 'Your help has arrived!',
          title: 'Help List',
          text: help_list(data),
          color: YELLOW
        },
        nil,
        data
      )
    else
      chat_attachment(
        {
          title: 'Help Error',
          fallback: 'Plugins or Commands not Found!',
          text: "Sorry <@#{data.user}>, I did not find any help commands or plugins to list",
          color: RED
        },
        nil,
        data
      )
    end
  end

  def reload(data)
    chat_attachment(
      {
        title: 'Plugin Reloader',
        text: 'Plugins are being reloaded, please wait',
        color: YELLOW
      },
      nil,
      data
    )
    reload_plugins
    chat_attachment(
      {
        title: 'Plugin Reloader',
        text: 'Plugins Reloaded Successfully',
        color: GREEN
      },
      nil,
      data
    )
  end

  def plugin(data)
    if verify(data)
      exec_data = exec(data)
      if exec_data
        chat_attachment(
          {
            title: "Plugin: #{requested_plugin(data)}",
            fallback: 'Plugin Responded',
            text: exec_data,
            color: exec_data.include?('Error') ? RED : GREEN
          },
          nil,
          data
        )
      else
        @logger.debug('SLAPI: Plugin Response was Blank, not posting to room')
      end
    elsif !@bot_options['mute_fail']
      @logger.debug("Slapi: No matching plugin for #{data.user} request")
      chat_attachment(
        {
          title: 'Plugin Error',
          fallback: 'No Plugin Found!',
          text: "Sorry <@#{data.user}>, I did not understand or find that command.",
          color: RED
        },
        nil,
        data
      )
    end
  end
end
