# frozen_string_literal: true
require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'
require 'json'
require 'logger'
require_relative 'lib/core/realtime'

# SLAPI Init
class Slapi < Sinatra::Application
  register Sinatra::ConfigFile
  # enable :sessions

  config_file 'config/environments.yml'

  set :environment, :production

  configure :production, :development, :test do
    enable :logging
  end

  #logger.info(settings)

  @realtime = RealTimeClient.new settings
end

require_relative 'lib/init'
