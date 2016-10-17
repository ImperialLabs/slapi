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
    Slack.configure do |config|
      config.token = settings.SLACK_API_TOKEN
      raise 'Missing SLACK_API_TOKEN configuration!' unless config.token
    end
    @client = Slack::RealTime::Client.new
    # TODO: Authorization test does not work for realtime client
    # @client.auth_test
    @plugins = Plugins.new
    @bot_name = settings.bot_name
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
    @client.on :hello do
      puts "Successfully connected, welcome '#{@client.self.name}' to the '#{@client.team.name}' team at https://#{@client.team.domain}.slack.com."
    end

    @client.on :message do |data|
      puts data
      case data.text
      when /#{@bot_name} ping| @#{@bot_name} ping/ then
          @client.web_client.chat_postMessage channel: data.channel,
                                              text: 'PONG'
      # Reads from configuration for bot name
      # TODO: get bot name from Slack
      when /#{@bot_name} | @#{@bot_name} / then
        output = @plugins.exec data
        if output && !output.empty?
          @client.web_client.chat_postMessage channel: data.channel,
                                              text: output
        # TODO: could simply not respond at all or make configurable.
        else
          @client.web_client.chat_postMessage channel: data.channel,
                                              text: "Hi <@#{data.user}>, I did not understand that command."
        end
      end
    end

    # Need to use async because @client.start! will block the rest of the program
    # execution in the event listener loop.
    @client.start_async
  end
end
