#TODO: there is likely a cleaner way to do the dependency injection than this but these PORO's work
class MockSettings
  attr_accessor :help, :admin, :adapter, :bot, :plugins
  def initialize(data)
    @help = data[:help] || {'level' => 1}
    @admin = data[:admin] || nil
    @adapter = data[:adapter] ? data[:adapter] : {'token' => 'abc123'}
    @bot = data[:bot] ? data[:bot] : {'name' => 'headroom'}
    @plugins = data[:plugins] ? data[:plugins] : {'location' => '../../spec/fixtures/plugins/*.yml'}
  end
end

class MockData
  attr_accessor :type, :channel, :text, :user, :ts, :team
  def initialize(data)
    @type = data[:type] ? data[:type] : 'message'
    @channel = data[:channel] ? data[:channel] : 'ABC123'
    @text = data[:text] ? data[:text] : '<@ABC123> help'
    @user = data[:user] ? data[:user] : 'ABC123'
    @ts = data[:ts] ? data[:ts] : '1486678775.000385'
    @team = data[:team] ? data[:team] : 'ABC123'
  end
end