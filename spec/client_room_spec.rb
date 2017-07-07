# frozen_string_literal: true
require_relative '../lib/client/bot.rb'
require 'spec_helper'

RSpec.describe Bot, '#exec' do

  before(:all) do
    @bot_id = 'U4DEAQX1T'
    @bot = Bot.new(MockSettings.new)
    @bot.run
  end

  describe 'run bot tests' do

    it 'configures and returns successfully' do
      expect(@bot.bot_name).to eq('integration_bot')
    end

    it 'runs bot ping' do
      mock = MockData.new(channel: 'C445NT42J', text: "<@#{@bot_id}> ping")
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq('PONG')
    end

    it 'runs bot get help' do
      mock = MockData.new(channel: 'C445NT42J', text: "<@#{@bot_id}> help")
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help for plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: "<@#{@bot_id}> help parse-default")
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('parse all data from slack')
    end

    it 'runs bot plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: "<@#{@bot_id}> hello-default world")
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq("Hello World!\n")
    end

    it 'runs bot get help for bad plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: "<@#{@bot_id}> help no_plugin")
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq('Sorry <@ABC123>, I did not find any help commands or plugins to list')
    end

    it 'runs bot bad plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: "<@#{@bot_id}> no_plugin")
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq('Sorry <@ABC123>, I did not understand or find that command.')
    end
  end
end
