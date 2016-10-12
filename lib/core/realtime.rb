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
      when 'bot hi' then
        @client.web_client.chat_postMessage channel: data.channel,
                                            text: "Hi <@#{data.user}>!"
      # it is here that I believe we should parse the second word as the name of the plugin.
      # Then forward on the request to the plugin based on configuration.
      # May need a check for configuration of and
      when /^bot/ then

        output = @plugins.exec data
        @client.web_client.chat_postMessage channel: data.channel,
                                            text: output
      end
    end

    # Need to use async because @client.start! will block the rest of the program
    # execution in the event listener loop.
    @client.start_async
  end
end
