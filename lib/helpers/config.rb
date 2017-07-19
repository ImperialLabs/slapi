# frozen_string_literal: true

# Slapi Config Helper Module
# 1. Determines config file to load
module Config
  def file
    return '../config/bot.test.yml' if File.file?('config/bot.test.yml')
    return '../config/bot.local.yml' if File.file?('config/bot.local.yml')
    return '../config/bot.yml' if File.file?('config/bot.yml')
    raise 'No bot config found' if File.file?('config/bot*yml')
  end
end
