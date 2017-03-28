# frozen_string_literal: true
# TODO: there is likely a cleaner way to do the dependency injection than this but these PORO's work
class MockSettings
  attr_accessor :help, :admin, :adapter, :bot, :plugins, :logger_level, :port, :environment
  def initialize(data = {})
    @config = YAML.load_file(File.expand_path('../../config/bot.test.yml', File.dirname(__FILE__)))
    @help = data[:help] || @config['help']
    @admin = data[:admin] || @config['admin']
    @logger_level = @config['logger_level'] || 'error'
    @adapter = @config['adapter']
    @bot = @config['bot']
    @plugins = @config['plugins']
    @port = '4567'
    @environment = 'test'
  end
end

class MockData
  attr_accessor :type, :channel, :text, :user, :ts, :team, :constructed, :data_hash
  def initialize(data)
    @type = data[:type] ? data[:type] : 'message'
    @channel = data[:channel] ? data[:channel] : 'ABC123'
    @text = data[:text] ? data[:text] : '<@U4DEAQX1T> help'
    @user = data[:user] ? data[:user] : 'ABC123'
    @ts = data[:ts] ? data[:ts] : '1486678775.000385'
    @team = data[:team] ? data[:team] : 'ABC123'
    @data_hash = {
      type: @type,
      channel: @channel,
      text: @text,
      user: @user,
      ts: @ts,
      team: @team
    }
    @constructed = OpenStruct.new(@data_hash)
  end
end
