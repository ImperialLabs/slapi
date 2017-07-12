# frozen_string_literal: true
require_relative '../lib/client/bot.rb'
require 'spec_helper'

RSpec.describe Bot, '#exec' do

  before(:all) do
    @bot_id = 'U4DEAQX1T'
    @dm_bot = Bot.new(MockSettings.new(help: { 'dm_user' => true, 'level' => 1 }))
    @dm_bot.run
  end

  describe 'run bot DM plugin exec tests' do
    it 'calls ping from DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'ping', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('PONG')
    end
    it 'calls plugin from DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'hello-default world', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('Hello World')
    end

    it 'calls plugin from DM without args without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'hello-default', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('No World')
    end

    it 'calls plugin from DM with bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: "<@#{@bot_id}> hello-default world", user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('Hello World')
    end

    it 'calls plugin from DM with args without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: "<@#{@bot_id}> hello-default", user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('No World')
    end
  end

  describe 'run bot DM help list' do
    it 'calls ping from DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'ping', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('PONG')
    end
    it 'runs bot get help list in room and expects DM response' do
      mock = MockData.new(channel: 'C445NT42J', text: "<@#{@bot_id}> help", user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('reload all plugins', 'simple hello world', 'passive container test')
    end

    it 'runs bot get help list in DM' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: "<@#{@bot_id}> help", user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('reload all plugins', 'simple hello world', 'passive container test')
    end

    it 'runs bot get help in DM with bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: "<@#{@bot_id}> help parse-default", user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('parse all data from slack')
    end

    it 'runs bot get help list for DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'help', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('reload all plugins', 'simple hello world', 'passive container test')
    end

    it 'runs bot get help for DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'help parse-default', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to include('parse all data from slack')
    end
  end
end