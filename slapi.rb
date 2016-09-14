require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'

# SLAPI Init
class SLAPI < Sinatra::Base
  register Sinatra::ConfigFile
  # enable :sessions
  config_file 'config/environments.yml'

  set :environment, :production

  configure :production, :development, :test do
    enable :logging
  end

end

require_relative 'lib/init'
