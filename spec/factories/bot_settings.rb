# frozen_string_literal: true

FactoryGirl.define do
  factory :bot_settings do
    config { YAML.load_file(File.expand_path('../../config/bot.test.yml', File.dirname(__FILE__))) }
    help config['help']
    admin config['admin']
    logger_level config['logger_level']
    adapter config['adapter']
    bot config['bot']
    plugins config['plugins']
    port '4567'
    environment 'test'
  end
end