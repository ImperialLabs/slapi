# frozen_string_literal: true

require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'

# Sinatra Extension for Chat Access
# Its main functions are to:
#  1. Route Messages to Client
#     - Standard Text Chat
#     - Emote Chat
#     - Attachment Chat
class Slapi < Sinatra::Base
  # Handles a POST request for '/v1/attachment'
  # @see https://api.slack.com/docs/message-attachments Slack Documentation
  # @see https://api.slack.com/docs/messages/builder
  #
  # @param [Hash] params the parameters sent on the request
  # @option params [String] :channel The Slack Channel ID (Public Channel Name works, private requires ID)
  # @option params [Hash] attachments the information about the attachments
  # @option attachments [String] :fallback
  # @option attachments [String] :pretext
  # @option attachments [String] :title
  # @option attachments [String] :title_link
  # @option attachments [String] :text
  # @option attachments [String] :color ('#229954') defaults to @bot::GREEN(constant) if not specified
  # @return [Integer] returns status
  post '/v1/formatted' do
    raise 'missing channel' unless params[:channel]
    raise 'missing text' unless params[:attachment][:text]
    raise 'missing fallback' unless params[:attachment][:fallback]
    raise 'missing title' unless params[:attachment][:title]
    @@bot.adapter.formatted(params[:channel], params[:attachment])
    status 200
  end

  # Changed primary route name, leaving here until documentation and tests are updated
  post '/v1/attachment' do
    redirect '/v1/formatted'
  end

  # Handles a POST request for '/v1/speak'
  # @see https://api.slack.com/docs/message-formatting Slack Documentation
  # @see https://api.slack.com/docs/messages/builder
  #
  # @param [Hash] params the parameters sent on the request
  # @option params [String] :channel The Slack Channel ID (ID only supported by Emote)
  # @option params [String] :text The text that will be posted in the channel, supports formatting
  # @return [Integer] returns status
  post '/v1/emote' do
    raise 'missing channel' unless params[:channel]
    raise 'missing text' unless params[:text]

    @@bot.adapter.message('emote', params[:channel], params[:text], params[:user]) if params[:user]
    @@bot.adapter.message('emote', params[:channel], params[:text]) unless params[:user]
    status 200
  end

  # Handles a POST request for '/v1/speak'
  # @see https://api.slack.com/docs/message-formatting Slack Documentation
  # @see https://api.slack.com/docs/messages/builder
  #
  # @param [Hash] params the parameters sent on the request
  # @option params [String] :channel The Slack Channel ID (Public Channel Name works, private requires ID)
  # @option params [String] :text The text that will be posted in the channel, supports formatting
  # @return [Integer] returns status
  post '/v1/speak' do
    raise 'missing channel' unless params[:channel]
    raise 'missing text' unless params[:text]

    @@bot.adapter.message('plain', params[:channel], params[:text], params[:user]) if params[:user]
    @@bot.adapter.message('plain', params[:channel], params[:text]) unless params[:user]
    status 200
    status 200
  end

  # Handles a POST request for '/v1/ping'
  # @return [String] returns pong
  get '/ping' do
    return 'pong'
  end
end

