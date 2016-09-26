# frozen_string_literal: true
require 'json'
require 'logger'
require 'slack-ruby-client'

# SLAPI class is for the API to interact with Slack
#
# == Ruby Slack Client
# The ruby Slack client will be used to connect into Slack
# @see https://github.com/slack-ruby/slack-ruby-client
class Slapi < Sinatra::Application
  def initialize
    #puts settings.environment
    #puts settings.SLACK_API_TOKEN
    #logger.warning(settings)
    Slack.configure do |config|
      config.token = settings.SLACK_API_TOKEN
      raise 'Missing SLACK_API_TOKEN configuration!' unless config.token
    end

    @client = Slack::Web::Client.new
    @client.auth_test
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

    logger.info('attach was called')
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
    logger.info('attached to room')
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
  post '/v1/emote' do
    logger.info('emote was called')
    # interestingly... this did not work with name of room, only ID
    @client.chat_meMessage(channel: params[:channel],
                           text: params[:text])
    logger.info('posted to room')
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
    logger.info('speak was called')
    @client.chat_postMessage(channel: params[:channel],
                             text: params[:text],
                             as_user: params[:as_user] ? params[:as_user] : true)
    logger.info('posted to room')
    status 200
    { 'message' => 'yes, it worked' }.to_json
  end
end
