# frozen_string_literal: true

require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'

# Sinatra Extension for Adapter Access
# Its main functions are to:
#  1. Allow Message Forwarding from Chat Adapter
class Slapi < Sinatra::Base
  # Handles a POST request for '/v1/messages'
  # @return [Integer] returns status 200 if succesful
  post '/v1/messages' do
    begin
      @@bot.listener(params) unless params.empty?
      status 200
    rescue => e
      status 500
      body "[ERROR] - Received #{e}"
      logger.error("[ERROR] - Received #{e}")
    end
  end
end
