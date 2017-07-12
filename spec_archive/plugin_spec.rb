# frozen_string_literal: true

require_relative '../lib/plugins/plugin.rb'
require_relative '../lib/plugins/helpers/network.rb'
require 'httparty'
require 'spec_helper'
require 'yaml'

RSpec.describe Plugin, '#exec' do
  before(:all) do
    rackup = File.expand_path('../../bin/rackup', __FILE__)
    @rack_pid = spawn("#{rackup} -D -E test -o 0.0.0.0 -p 4567", close_others: true)
    settings = MockSettings.new(plugins: { 'location' => '../../spec/fixtures/plugins/' })
    @plugin_hash = {}
    port_start = 48230
    yaml_files = File.expand_path('fixtures/plugins/*.yml', File.dirname(__FILE__))
    @network = Network.new
    Dir.glob(yaml_files).each do |file|
      dynamic_port = @network.port_find(port_start)
      @plugin_hash[File.basename(file, '.*')] = Plugin.new(file, dynamic_port, settings)
      port_start = dynamic_port + 1
    end
  end

  after(:all) do
    Process.kill('HUP', @rack_pid)
    Process.wait @rack_pid
  end

  describe 'calls exec on plugins' do
    it 'run exec on script type plugin' do
      mock = MockData.new(text: '<@U4DEAQX1T> hello world')
      expect(@plugin_hash['hello'].exec('U4DEAQX1T', mock.constructed)).to include('Hello World')
    end

    it 'run exec on container passive type plugin' do
      mock = MockData.new(text: '<@U4DEAQX1T> parse')
      expect(@plugin_hash['parse'].exec('U4DEAQX1T', mock.constructed)).to include('message', 'ABC123', 'parse')
    end

    it 'run exec on container active type plugin' do
      mock = MockData.new(text: '<@U4DEAQX1T> active-parse')
      expect(@plugin_hash['active-parse'].exec('U4DEAQX1T', mock.constructed)).to include('message', 'ABC123', 'active-parse')
    end
  end

  describe 'validates language return' do
    it { expect(@plugin_hash['hello'].lang_settings('ruby')).to include(file_type: '.rb', image: 'slapi/ruby:latest') }
    it { expect(@plugin_hash['hello'].lang_settings('python')).to include(file_type: '.py', image: 'slapi/python:latest') }
    it { expect(@plugin_hash['hello'].lang_settings('node')).to include(file_type: '.js', image: 'slapi/nodejs:latest') }
    it { expect(@plugin_hash['hello'].lang_settings('bash')).to include(file_type: '.sh', image: 'slapi/base:latest') }
    it { expect(@plugin_hash['hello'].lang_settings).to include(file_type: '.sh', image: 'slapi/base:latest') }
  end

  describe 'run API plugin tests' do
    it 'starts bot and verifies api endpoint' do
      @response = OpenStruct.new(body: nil)

      while @response.body.blank?
        begin
          @response = HTTParty.get('http://localhost:4567/ping')
        rescue StandardError
          sleep(1)
        end
      end

      expect(@response.body).to eq('pong')
    end

    # Identical Plugins, Test between a Dockerfile build and Dockerhub pull
    it 'run exec on api type plugin', slack: true do
      mock = MockData.new(text: '<@ABC123> api-pull hello', channel: 'C445NT42J')
      expect(@plugin_hash['api-pull'].exec('U4DEAQX1T', mock.constructed)).to eq(200)
    end

    it 'run bad option on api type plugin' do
      mock = MockData.new(text: '<@ABC123> api-pull fail')
      expect(@plugin_hash['api-pull'].exec('U4DEAQX1T', mock.constructed)).to eq('Error: Received code 404')
    end

    it 'run save to brain on api type plugin' do
      mock = MockData.new(text: '<@ABC123> api-build save test value', channel: 'C445NT42J')
      expect(@plugin_hash['api-build'].exec('U4DEAQX1T', mock.constructed)).to eq(200)
    end

    it 'run search for hash in brain on api type plugin' do
      mock = MockData.new(text: '<@ABC123> api-build search', channel: 'C445NT42J')
      expect(@plugin_hash['api-build'].exec('U4DEAQX1T', mock.constructed)).to eq(200)
    end

    it 'run search for key in brain on api type plugin' do
      mock = MockData.new(text: '<@ABC123> api-build search test', channel: 'C445NT42J')
      expect(@plugin_hash['api-build'].exec('U4DEAQX1T', mock.constructed)).to eq(200)
    end

    it 'run delete for key in brain on api type plugin' do
      mock = MockData.new(text: '<@ABC123> api-build delete test', channel: 'C445NT42J')
      expect(@plugin_hash['api-build'].exec('U4DEAQX1T', mock.constructed)).to eq(200)
    end
  end
end
