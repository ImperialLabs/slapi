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
    @plugins = Plugins.new
    @bot_name = settings.bot['name']
    # Adding for later use
    @help_options = settings.help || {}
    @admin_options = settings.admin || {}
  end

  # Avoid potential empty variable so bot responds to all items that start with @
  def bot_name
    if @bot_name.nil?
      @bot_name = @client.self.name
    end
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
      puts data
      case data.text
      when /^#{@bot_name} ping|^@#{@bot_name} ping|^\<@#{@client.self.id}\> ping/ then
          @client.web_client.chat_postMessage channel: data.channel,
                                              text: 'PONG'
      # Reads from configuration for bot name or uses the bot name/id from Slack
      when /^#{@bot_name} |^@#{@bot_name} |^\<@#{@client.self.id}\> / then
        output = @plugins.exec data
        if output && !output.empty?
          @client.web_client.chat_postMessage channel: data.channel,
                                              text: output
        # TODO: could simply not respond at all or make configurable.
        else
          @client.web_client.chat_postMessage channel: data.channel,
                                              text: "Hi <@#{data.user}>, I did not understand that command."
        end
      # TODO: Work in config options to utilize help in the appropriate way.
      # TODO: Decide on how to cache help data to be able to post in chat
      #when /^#{@bot_name} help|^@#{@bot_name} help|^\<@#{@client.self.id}\> help/ then
        # TODO: Make output function based on config options (level 1 or 2)
        #output = @plugins.help data
        #if output && !output.empty?
        # TODO: add ability to switch responses from channel or DM based on config settings
        #  @client.web_client.chat_postMessage channel: data.channel,
        #                                      text: output
        #else
        #  @client.web_client.chat_postMessage channel: data.channel,
        #                                      text: "Sorry <@#{data.user}>, I could not find any help information on that"
        #end
        # TODO: Add another listener specific to help command ?
      end
    end

    # Need to use async because @client.start! will block the rest of the program
    # execution in the event listener loop.
    @client.start_async
  end
end
