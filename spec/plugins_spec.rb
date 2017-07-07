require_relative '../lib/plugins/plugins.rb'
require 'spec_helper'

RSpec.describe Plugins, '#exec' do
  context 'normal plugins setting test' do
    let(:plugins) { Plugins.new(MockSettings.new) }
    it { expect(plugins.help_list('parse-default')).to include('parse all data') }
    it { expect(plugins.help_list).to include('parse', 'hello', 'ping', 'help') }
    it { expect(plugins.load).to be_a_kind_of(Array) }
  end

  context 'plugins settings with level 2 help' do
    let(:plugins) { Plugins.new(MockSettings.new(help: { 'level' => 2 })) }
    it { expect(plugins.help_list).to include('parse all data', 'hello world') }
  end
end
