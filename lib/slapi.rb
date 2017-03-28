# frozen_string_literal: true
require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'
require 'logger'
require 'json'
require 'yaml'
require 'docker'
require 'httparty'

# Routes
require_relative 'routes/plugin'
require_relative 'routes/chat'
require_relative 'routes/brain'

# Internal
require_relative 'brain/redis'
require_relative 'client/bot'

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

  # Helpers
  require_relative 'helpers/bot'
  require_relative 'helpers/brain'
  require_relative 'helpers/plugins'

  config_file '../config/environments.yml'

  if File.file?('config/bot.test.yml')
    config_file '../config/bot.test.yml'
  elsif File.file?('config/bot.local.yml')
    config_file '../config/bot.local.yml'
  elsif File.file?('config/bot.yml')
    config_file '../config/bot.yml'
  else
    raise 'No bot config found'
  end

  configure :production, :test, :development do
    enable :logging
  end

  register Sinatra::SlapiRoutes::Plugin
  register Sinatra::SlapiRoutes::Chat
  register Sinatra::SlapiRoutes::Brain

  @logger = Logger.new(STDOUT)
  @logger.level = settings.logger_level

  # Logging outside of requests is not available in Sinatra unless you do something like this:
  # http://stackoverflow.com/questions/14463512/how-do-i-access-sinatras-logger-outside-the-request-scope

  @logger.debug("Slapi: Current environment is set to: #{settings.environment}")

  # Load Brain
  # Utilizes library from brain/redis
  @brain = Brain.new(settings)

  # Run Slapi Bot/Slack Client
  # Utilizes Library from client/bot
  @bot = Bot.new(settings)
  @bot.run
end
