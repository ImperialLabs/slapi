# frozen_string_literal: true
require 'json'
require 'logger'
require 'slack-ruby-client'
require_relative '../plugin/plugins'

# RealTimeClient class sets up a listener as a bot in the Slack Channel to route
# the messages to the appropriate location.
#
# == Ruby Slack Client
# The ruby Slack client will be used to connect into Slack
# @see https://github.com/slack-ruby/slack-ruby-client
class RealTimeClient
  def initialize(settings, plugins)
    Slack.configure do |config|
      config.token = settings.SLACK_API_TOKEN
      raise 'Missing SLACK_API_TOKEN configuration!' unless config.token
    end

    # To test real time client: https://api.slack.com/methods/rtm.start/test
    @client = Slack::RealTime::Client.new
    # TODO: Authorization test does not work for realtime client
    # @client.auth_test
    @plugins = plugins
  end

  def update_plugin_cache plugins
    @plugins = plugins
  end

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
        #@client.web_client.chat_postMessage channel: data.channel,
                                            #text: "Sorry <@#{data.user}>, what?"
        @plugins.exec data
      end
    end

    # Need to use async because @client.start! will block the rest of the program
    # execution in the event listener loop.
    @client.start_async
  end
end
