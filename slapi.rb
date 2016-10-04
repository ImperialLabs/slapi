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

  configure :production, :development, :test do
    enable :logging
  end

  # Environment should be set outside of application be either:
  # RACK_ENV=production
  # sending in the -E flag as in: unicorn -c path/to/unicorn.rb -E development -D
  set :environment, :production

  # Logging outside of requests is not available in Sinatra unless you do something like this:
  # http://stackoverflow.com/questions/14463512/how-do-i-access-sinatras-logger-outside-the-request-scope
  # TODO: set up Rack Logger
  # logger.debug "current environment is set to: #{settings.environment}"
  # TODO: also set up log to write to log file
  puts "current environment is set to: #{settings.environment}"

  @realtime = RealTimeClient.new settings
  @realtime.run_bot
end

require_relative 'lib/init'
