# frozen_string_literal: true
require 'json'
require 'logger'
require 'slack-ruby-client'
require_relative 'plugins'

# RealTimeClient class sets up a listener as a bot in the Slack Channel to route
# the messages to the appropriate location.
#
# == Ruby Slack Client
# The Ruby Slack client will be used to connect, listen and post into Slack
# @see https://github.com/slack-ruby/slack-ruby-client
# To test real time client: https://api.slack.com/methods/rtm.start/test
class RealTimeClient
  def initialize(settings)
    # TODO: Make non-slack specific to enable other adapters?
    Slack.configure do |config|
      config.token = settings.adapter['token']
      raise 'Missing Slack Token configuration!' unless config.token
    end
    @client = Slack::RealTime::Client.new
    # TODO: Authorization test does not work for realtime client
    # @client.auth_test
    @plugins = Plugins.new(settings)
    @bot_name = settings.bot['name']
    @bot_options = settings.bot || {}
    # Adding for later use
    @help_options = settings.help || {}
    @admin_options = settings.admin || {}
  end

  # Avoid potential empty variable so bot responds to all items that start with @
  def bot_name
    @bot_name = @bot_options['name'] || @client.self.name
  end

  # Reload all of the plugins from configuration files
  def update_plugin_cache
    @plugins.load
  end

  # Start the bot and define the listeners
  #
  # has a basic 'hello' to act as a ping.
  # will route all messages that start with 'bot' to the Plugins class to route to the correct plugin
  def run_bot
    # Ensure there is a bot name to be referenced
    bot_name
    @client.on :hello do
      puts "Successfully connected, welcome '#{@client.self.name}' to the '#{@client.team.name}' team at https://#{@client.team.domain}.slack.com."
    end

    @client.on :message do |data|
      # Clean up listners and don't require @bot if in a DM
      @bot_prefix = "(^#{@bot_name}|^@#{@bot_name}|^\<@#{@client.self.id}\>) " unless data.channel[0] == 'D'
      @bot_prefix = '^' if data.channel[0] == 'D'
      puts data
      if data.user != @client.self.id
        case data.text
        when /#{@bot_prefix}ping/ then
          @client.web_client.chat_postMessage channel: data.channel,
                                              as_user: true,
                                              attachments:
                                              [
                                                {
                                                  title: 'Bot Check',
                                                  text: 'PONG',
                                                  color: '#229954'
                                                }
                                              ]
        when /#{@bot_prefix}help/ then
          help_return = @plugins.help data
          # Remove when doing level 2 help or responding with specific plugin help
          help_text = "Please use `@#{@bot_name} help plugin_name` for specific info" unless (data.text.include? "#{@bot_prefix}help ") || (@help_options['level'] == 2)
          # Set channel to post based on dm_user option
          help_channel = data.channel unless @help_options['dm_user']

          if @help_options['dm_user']
            # if doing dm_user under help, create DM and set channel ID for chat post
            dm_info = @client.web_client.im_open user: data.user
            help_channel = dm_info['channel']['id']
            # Remove prefix to allow using commands with @bot
            @bot_prefix = ''
          end

          if help_return && !help_return.empty?
            @client.web_client.chat_postMessage channel: help_channel,
                                                as_user: true,
                                                attachments:
                                                [
                                                  {
                                                    pretext: help_text,
                                                    fallback: 'Your help has arrived!',
                                                    title: 'Help List',
                                                    text: help_return,
                                                    color: '#F7DC6F'
                                                  }
                                                ]
          else
            @client.web_client.chat_postMessage channel: help_channel,
                                                as_user: true,
                                                attachments:
                                                [
                                                  {
                                                    title: 'Help Error',
                                                    fallback: 'Plugins or Commands not Found!',
                                                    text: "Sorry <@#{data.user}>, I did not find any help commands or plugins to list",
                                                    color: '#A93226'
                                                  }
                                                ]
          end
        when /#{@bot_prefix}reload/ then
          @client.web_client.chat_postMessage channel: data.channel,
                                              as_user: true,
                                              attachments:
                                              [
                                                {
                                                  title: 'Plugin Reloader',
                                                  text: 'Plugins are being reloaded, please wait',
                                                  color: '#F7DC6F'
                                                }
                                              ]
          update_plugin_cache
          @client.web_client.chat_postMessage channel: data.channel,
                                              as_user: true,
                                              attachments:
                                              [
                                                {
                                                  title: 'Plugin Reloader',
                                                  text: 'Plugins Reloaded Successfully',
                                                  color: '#229954'
                                                }
                                              ]
        # Reads from configuration for bot name or uses the bot name/id from Slack
        # TODO: Create Phrases for Plugins: Create a phrase lookup for plugins that need unique listeners
        when /#{@bot_prefix}/ then
          if data.text.include? ' '
            # Create array based on spaces
            data_array = data.text.split(' ')
            requested_plugin = data_array[1] unless data.channel[0] == 'D'
            requested_plugin = data_array[0] if data.channel[0] == 'D'
          elsif data.text.exclude? @client.self.id
            requested_plugin = data.text
          end

          plugin_return = @plugins.exec(requested_plugin, data) if requested_plugin

          # phrase_return = @plugins.phrase_lookup data
          if plugin_return && !plugin_return.empty?
            data_array = data.text.split(' ')
            requested_plugin = data_array[1] unless data.channel[0] == 'D'
            requested_plugin = data_array[0] if data.channel[0] == 'D'
            @client.web_client.chat_postMessage channel: data.channel,
                                                as_user: true,
                                                attachments:
                                                [
                                                  {
                                                    title: "Plugin: #{requested_plugin}",
                                                    fallback: 'Plugin Responded',
                                                    text: plugin_return,
                                                    color: '#229954'
                                                  }
                                                ]
          # elsif phrase_return && !phrase_return.empty?
          #   @client.web_client.chat_postMessage channel: data.channel,
          #                                       text: phrase_return
          # TODO: could simply not respond at all or make configurable.
          elsif !@bot_options['mute_fail']
            @client.web_client.chat_postMessage channel: data.channel,
                                                as_user: true,
                                                attachments:
                                                [
                                                  {
                                                    title: 'Plugin Error',
                                                    fallback: 'No Plugin Found!',
                                                    text: "Sorry <@#{data.user}>, I did not understand or find that command.",
                                                    color: '#A93226'
                                                  }
                                                ]
          end
        end
      end
    end
    # Need to use async because @client.start! will block the rest of the program
    # execution in the event listener loop.
    @client.start_async
  end
end
