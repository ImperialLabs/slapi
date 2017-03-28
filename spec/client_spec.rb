# frozen_string_literal: true
require_relative '../lib/client/bot.rb'
require 'spec_helper'
require 'ostruct'

RSpec.describe Bot, '#exec' do

  describe 'run bot tests' do
    before(:all) do
      @bot = Bot.new(MockSettings.new)
      @bot.run
    end

    it 'configures and returns successfully' do
      expect(@bot.bot_name).to eq('integration_bot')
    end

    it 'runs bot ping' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> ping')
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq('PONG')
    end

    it 'runs bot reload' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> reload')
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq('Plugins Reloaded Successfully')
    end

    it 'runs bot get help' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> help')
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help for plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> help parse')
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help for bad plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> help no_plugin')
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq('Sorry <@ABC123>, I did not find any help commands or plugins to list')
    end

    it 'runs bot plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> hello world')
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq("Hello World!\n")
    end

    it 'runs bot bad plugin' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> no_plugin')
      response = @bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq('Sorry <@ABC123>, I did not understand or find that command.')
    end
  end

  describe 'run bot tests' do
    before(:all) do
      @dm_bot = Bot.new(MockSettings.new(help: { 'dm_user' => true, 'level' => 1 }))
      @dm_bot.run
    end

    it 'calls plugin from DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'hello world', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq("Hello World!\n")
    end

    it 'calls plugin from DM without args without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'hello', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq("No World!\n")
    end

    it 'calls plugin from DM with bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: '<@U4DEAQX1T> hello world', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq("Hello World!\n")
    end

    it 'calls plugin from DM with args without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: '<@U4DEAQX1T> hello', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['text']).to eq("No World!\n")
    end

    it 'calls plugin from DM' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'help', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help list and expects DM' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> help', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help and expects DM' do
      mock = MockData.new(channel: 'C445NT42J', text: '<@U4DEAQX1T> help parse', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help list in DM' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: '<@U4DEAQX1T> help', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help in DM' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: '<@U4DEAQX1T> help parse', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help list for DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'help', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end

    it 'runs bot get help for DM without bot name' do
      mock = MockData.new(channel: 'D4FJHFBCK', text: 'help parse', user: 'U4F0KFA73')
      response = @dm_bot.listener(mock.constructed)
      expect(response['message']['attachments'][0]['fallback']).to eq('Your help has arrived!')
    end
  end
end
