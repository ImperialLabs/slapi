# frozen_string_literal: true
require_relative '../lib/plugins/plugin.rb'
require 'spec_helper'

RSpec.describe Plugin, '#exec' do
  context 'calls exec on plugins' do
    it 'run exec on script type plugin' do
      hello_file = File.expand_path('fixtures/plugins/hello.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      plugin = Plugin.new(hello_file, 48232, settings)
      mock = MockData.new(text: '<@U4DEAQX1T> hello world')
      expect(plugin.exec('U4DEAQX1T', mock.constructed)).to include('Hello World')
    end

    it 'run exec on container passive type plugin' do
      parse_file = File.expand_path('fixtures/plugins/parse.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      plugin = Plugin.new(parse_file, 48233, settings)
      mock = MockData.new(text: '<@U4DEAQX1T> parse')
      expect(plugin.exec('U4DEAQX1T', mock.constructed)).to include('message', 'ABC123', 'parse')
    end

    it 'run exec on container active type plugin' do
      parse_file = File.expand_path('fixtures/plugins/active-parse.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      plugin = Plugin.new(parse_file, 48234, settings)
      mock = MockData.new(text: '<@U4DEAQX1T> active-parse')
      expect(plugin.exec('U4DEAQX1T', mock.constructed)).to include('message', 'ABC123', 'active-parse')
    end
  end

  context 'validates language return' do
    before(:each) do
      parse_file = File.expand_path('fixtures/plugins/hello.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      @lang_plugin = Plugin.new(parse_file, 48235, settings)
    end

    it 'returns ruby' do
      expect(@lang_plugin.lang_settings('ruby')).to include(file_type: '.rb', image: 'slapi/ruby:latest')
    end
    it 'returns python' do
      expect(@lang_plugin.lang_settings('python')).to include(file_type: '.py', image: 'slapi/python:latest')
    end
    it 'returns nodejs' do
      expect(@lang_plugin.lang_settings('node')).to include(file_type: '.js', image: 'slapi/nodejs:latest')
    end
    it 'returns shell' do
      expect(@lang_plugin.lang_settings('bash')).to include(file_type: '.sh', image: 'slapi/base:latest')
    end
    it 'returns shell for nil' do
      expect(@lang_plugin.lang_settings).to include(file_type: '.sh', image: 'slapi/base:latest')
    end
  end
end
