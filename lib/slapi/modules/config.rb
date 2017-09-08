# frozen_string_literal: true

# Slapi Config Helper Module
# 1. Determines config file to load
module Config
  class << self
    def bot_file
      return '../config/bot.test.yml' if File.file?('config/bot.test.yml')
      return '../config/bot.local.yml' if File.file?('config/bot.local.yml')
      return '../config/bot.yml' if File.file?('config/bot.yml')
      raise 'No bot config found' if File.file?('config/bot*yml')
    end

    def merge(config, merge_config)
      merge_config.each do |key, value|
        if value.is_a?(Array)
          value.each do |v|
            if v.is_a?(Hash)
              config[key] = v
            else
              config[key] << v
            end
          end
        elsif config[key].blank?
          config[key] = value
        end
      end
      config
    end
  end
end
