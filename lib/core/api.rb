# frozen_string_literal: true
require 'json'
require 'logger'
require 'slack-ruby-client'
require_relative '../plugin/plugins'

# SLAPI class is for the API to interact with Slack
#
# == Ruby Slack Client
# The ruby Slack client will be used to connect into Slack
# @see https://github.com/slack-ruby/slack-ruby-client
class Slapi < Sinatra::Application
  def initialize
    Slack.configure do |config|
      config.token = settings.SLACK_API_TOKEN
      raise 'Missing SLACK_API_TOKEN configuration!' unless config.token
    end

    @client = Slack::Web::Client.new
    @client.auth_test
  end

  post '/reload' do
    @plugins = Plugins.new
  end

  # Handles a POST request for '/v1/attachment'
  # @see https://api.slack.com/docs/message-attachments Slack Documentation
  # @see https://api.slack.com/docs/messages/builder
  #
  # @param [Hash] params the parameters sent on the request
  # @option params [String] :channel The Slack Channel ID (Name may work in some instances)
  # @option params [String] :text The text that will be posted in the channel
  # @option params [String] :as_user ('true')
  # @option params [Hash] attachments the information about the attachments
  # @option attachments [String] :fallback
  # @option attachments [String] :pretext
  # @option attachments [String] :title
  # @option attachments [String] :title_link
  # @option attachments [String] :text
  # @option attachments [String] :color ('#7CD197') defaults to green if not specified
  # @return [String] the resulting webpage
  post '/v1/attachment' do
    raise 'missing channel' unless params[:channel]
    raise 'missing text' unless params[:text]
    raise 'missing fallback' unless params[:attachments][:fallback]
    raise 'missing pretext' unless params[:attachments][:pretext]
    raise 'missing title' unless params[:attachments][:title]
    raise 'missing title_link' unless params[:attachments][:title_link]

    logger.debug('attach was called')
    @client.chat_postMessage(
      channel: params[:channel],
      text: params[:text],
      # TODO: test the falsiness here
      as_user: params[:as_user] ? params[:as_user] : true,
      attachments: [
        {
          fallback: params[:attachments][:fallback],
          pretext: params[:attachments][:pretext],
          title: params[:attachments][:title],
          title_link: params[:attachments][:title_link],
          text: params[:attachments][:text],
          color: params[:attachments][:color] ? params[:attachments][:color] : '#7CD197'
        }
      ].to_json
    )
    logger.debug('attached to room')
    status 200

    { 'message' => 'yes, it worked' }.to_json
  end

  # Handles a POST request for '/v1/speak'
  # @see https://api.slack.com/docs/message-formatting Slack Documentation
  # @see https://api.slack.com/docs/messages/builder
  #
  # @param [Hash] params the parameters sent on the request
  # @option params [String] :channel The Slack Channel ID (Name may work in some instances)
  # @option params [String] :text The text that will be posted in the channel, supports formatting
  # @return [String] the resulting webpage
  post '/v1/emote' do
    raise 'missing channel' unless params[:channel]
    raise 'missing text' unless params[:text]

    logger.debug('emote was called')
    # interestingly... this did not work with name of room, only ID
    @client.chat_meMessage(channel: params[:channel],
                           text: params[:text])
    logger.debug('posted to room')
    status 200
    { 'message' => 'yes, it worked' }.to_json
  end

  # Handles a POST request for '/v1/speak'
  # @see https://api.slack.com/docs/message-formatting Slack Documentation
  # @see https://api.slack.com/docs/messages/builder
  #
  # @param [Hash] params the parameters sent on the request
  # @option params [String] :channel The Slack Channel ID (Name may work in some instances)
  # @option params [String] :text The text that will be posted in the channel, supports formatting
  # @option params [String] :as_user ('true')
  # @return [String] the resulting webpage
  post '/v1/speak' do
    raise 'missing channel' unless params[:channel]
    raise 'missing text' unless params[:text]

    logger.debug('speak was called')
    @client.chat_postMessage(channel: params[:channel],
                             text: params[:text],
                             as_user: params[:as_user] ? params[:as_user] : true)
    logger.debug('posted to room')
    { 'message' => 'yes, it worked' }.to_json
  end
end
