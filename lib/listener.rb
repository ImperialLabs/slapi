# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'

# Adapter Class
# Its main functions are to:
#  1. Load Chat Adapter
#     - Find adapter in config
#     - Pull adapter container and load
module Listener
  def message_sort(data)
    case data.command
    when 'ping', 'Ping'
      @logger.debug("Slapi: #{data.user} requested ping")
      ping(data)
    when 'help', 'Help'
      @logger.debug("Slapi: #{data.user} requested help")
      get_help(data)
    when 'reload', 'Reload'
      @logger.debug("Slapi: #{data.user} requested plugin reload")
      reload(data)
    else
      @logger.debug("Slapi: #{data.user} request forwarded to check against plugins")
      plugin(data)
    end
  end
end
