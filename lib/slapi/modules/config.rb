# frozen_string_literal: true

# Slapi Config Helper Module
# 1. Determines config file to load
module Config
  class << self
    def bot_file
      if File.file?('config/bot.test.yml')
        'bot.test.yml'
      elsif File.file?('config/bot.local.yml')
        'bot.local.yml'
      elsif File.file?('config/bot.yml')
        'bot.yml'
      else
        raise 'No bot config found'
      end
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
