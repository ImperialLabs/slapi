# frozen_string_literal: true

require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'
require 'logger'
require 'json'

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

  Dir[File.dirname(__FILE__) + '**/**/*.rb'].each { |file| require file }

  @logger = Logger.new(STDOUT)
  @logger.level = settings.logger_level

  config_file '../config/environments.yml'
  config_file Config.bot_file

  configure :production, :test, :development do
    enable :logging
  end

  register Sinatra::SlapiRoutes::Plugin
  register Sinatra::SlapiRoutes::Chat
  register Sinatra::SlapiRoutes::Brain
  register Sinatra::SlapiRoutes::Adapter

  @logger.debug("Slapi: Current environment is set to: #{settings.environment}")

  @bot = Bot.new(settings)
  @bot.run
end
