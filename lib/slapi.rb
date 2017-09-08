# frozen_string_literal: true

require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'
require 'logger'
require 'json'
require_relative 'slapi/modules/config'
require_relative 'slapi/routes/init'
require_relative 'slapi/bot'

# Slapi Class - Primary Class
# Its main functions are to:
#  1. Set Sinatra Environment/Config
#     - configs loaded from ./config folder
#     - bot config has bot.local.yml then bot.yml preference
#  2. Creates Brain Instance
#     - lib/brain/redis.rb
#  3. Starts Bot
#     - lib/client/bot.rb
class Slapi < Sinatra::Base
  set :root, File.dirname(__FILE__)
  register Sinatra::ConfigFile

  set :json_content_type, :js

  set :brain, {}
  set :adapter, {}

  config_file '../config/environments.yml'
  config_file Config.bot_file

  configure :production, :test, :development do
    enable :logging
  end

  @@logger = Logger.new(STDOUT)
  @@logger.level = settings.logger_level

  @@logger.debug("Slapi: Current environment is set to: #{settings.environment}")

  @@bot = Bot.new(settings)
end
