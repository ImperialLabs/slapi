# frozen_string_literal: true
require_relative '../lib/plugins/plugin.rb'
require 'spec_helper'

RSpec.describe Plugin, '#exec' do

  context 'calls exec on plugins' do
    it 'run exec on script type plugin' do
      hello_file = File.expand_path('fixtures/plugins/hello.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      plugin = Plugin.new(hello_file, settings)
      mock = MockData.new(text: '<@ABC123> hello world')
      expect(plugin.exec(mock.constructed)).to eq("Hello World!\r\n")
    end

    it 'run exec on container type plugin' do
      parse_file = File.expand_path('fixtures/plugins/parse.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      plugin = Plugin.new(parse_file, settings)
      mock = MockData.new(text: '<@ABC123> parse')
      expect(plugin.exec(mock.constructed)).to eq("\x01\x00\x00\x00\x00\x00\x00\bmessage\n\x01\x00\x00\x00\x00\x00\x00\aABC123\n\x01\x00\x00\x00\x00\x00\x00\x10<@ABC123> parse\n")
    end
  end

  context 'validates language return' do
    before(:each) do
      parse_file = File.expand_path('fixtures/plugins/hello.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      @lang_plugin = Plugin.new(parse_file, settings)
    end

    it 'returns ruby' do
      expect(@lang_plugin.lang_settings('ruby')).to include(:file_type => '.rb', :image => 'slapi/ruby:latest')
    end
    it 'returns python' do
      expect(@lang_plugin.lang_settings('python')).to include(:file_type => '.py', :image => 'slapi/python:latest')
    end
    it 'returns nodejs' do
      expect(@lang_plugin.lang_settings('node')).to include(:file_type => '.js', :image => 'slapi/nodejs:latest')
    end
    it 'returns shell' do
      expect(@lang_plugin.lang_settings('bash')).to include(:file_type => '.sh', :image => 'slapi/base:latest')
    end
    it 'returns shell for nil' do
      expect(@lang_plugin.lang_settings).to include(:file_type => '.sh', :image => 'slapi/base:latest')
    end
  end
end
