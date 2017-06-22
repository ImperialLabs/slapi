require_relative '../lib/plugins/plugins.rb'
require 'spec_helper'

RSpec.describe Plugins, '#exec' do

  context 'calls specific help for parse plugin' do
    it 'returns help list successfully' do
      plugins = Plugins.new(MockSettings.new)

      expect(plugins.help_list('parse')).to include('parse all data')
    end
  end

  context 'calls help level 1' do
    it 'returns help list successfully' do
      plugins = Plugins.new(MockSettings.new)
      expect(plugins.help_list).to include('parse', 'hello', 'ping', 'help')
    end
  end

  context 'calls help level 2' do
    it 'returns help list successfully' do
      plugins = Plugins.new(MockSettings.new(help: { 'level' => 2 }))
      expect(plugins.help_list).to include('parse all data', 'hello world', 'Search for all keys')
    end
  end


  context 'update plugin cache' do
    it 'configures and returns successfully' do
      plugins = Plugins.new(MockSettings.new)
      expect(plugins.load).to be_a_kind_of(Array)
    end
  end
end
