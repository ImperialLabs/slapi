# frozen_string_literal: true
require_relative '../lib/plugins/plugin.rb'
require 'httparty'
require 'spec_helper'

RSpec.describe Plugin, '#exec' do
  before(:each) do
    rackup = File.expand_path('../../bin/rackup', __FILE__)
    @rack_pid = spawn("#{rackup} -D -E test -o 0.0.0.0 -p 4567", close_others: true)
  end

  after(:each) do
    Process.kill('HUP', @rack_pid)
    Process.wait @rack_pid
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

    it 'run exec on api type plugin' do
      api_file = File.expand_path('fixtures/plugins/api.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      plugin = Plugin.new(api_file, settings)
      mock = MockData.new(text: '<@ABC123> api hello', channel: 'C445NT42J')
      expect(plugin.exec('U4DEAQX1T', mock.constructed)).to eq(200)
    end

    it 'run bad option on api type plugin' do
      api_file = File.expand_path('fixtures/plugins/api.yml', File.dirname(__FILE__))
      settings = MockSettings.new
      plugin = Plugin.new(api_file, settings)
      mock = MockData.new(text: '<@ABC123> api fail')
      expect(plugin.exec('U4DEAQX1T', mock.constructed)).to eq('Error: Received code 404')
    end
  end
end
