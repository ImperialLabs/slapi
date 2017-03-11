require_relative '../lib/plugins/plugins.rb'
require 'spec_helper'

RSpec.describe Plugins, '#exec' do

  context 'calls specific help for parse plugin' do
    it 'returns help list successfully' do
      plugins = Plugins.new(MockSettings.new)

      expect(plugins.help_list('parse')).to eq("parse:\n    parse : parse all data from slack\n")
    end
  end

  context 'calls help level 1' do
    it 'returns help list successfully' do
      plugins = Plugins.new(MockSettings.new)
      list = plugins.help_list
      list == "hello\nparse\n" || "parse\nhello\n"
    end
  end

  context 'calls help level 2' do
    it 'returns help list successfully' do
      plugins = Plugins.new(MockSettings.new(help: { 'level' => 2 }))
      list = plugins.help_list

      list == "hello:\n    world : Says hello world\nparse:\n    parse : parse all data from slack\n" ||
        "parse:\n    parse : parse all data from slack\nhello:\n    world : Says hello world\n"
    end
  end


  context 'update plugin cache' do
    it 'configures and returns successfully' do
      plugins = Plugins.new(MockSettings.new)
      expect(plugins.load).to be_a_kind_of(Array)
    end
  end
end
