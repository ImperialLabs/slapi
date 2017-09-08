# frozen_string_literal: true

require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'

# Sinatra Extension for Plugin Access
# Its main functions are to:
#  1. Allow Reloading of Plugins via API
class Slapi < Sinatra::Base
  # Handles a POST request for '/v1/reload'
  # @return [Integer] returns status 200
  post '/reload' do
    @@bot.plugins.reload
    status 200
  end
end
