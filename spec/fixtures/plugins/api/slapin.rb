# frozen_string_literal: true
require 'json'
require 'httparty'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'
# require_relative 'party'

# Sinatra API App
class Slapin < Sinatra::Base
  set :root, File.dirname(__FILE__)
  register Sinatra::ConfigFile

  set :environment, :production

  config_file 'environments.yml'
  config_file 'api.yml' if File.file?('./api.yml')

  @headers = {}

  class PARTY #:nodoc:
    include HTTParty
    base_uri ENV['BOT_URL'] ? ENV['BOT_URL'] : settings.api.bot_url
  end

  post '/endpoint' do
    raise 'missing user' unless params[:chat][:user]
    raise 'missing channel' unless params[:chat][:channel]
    raise 'missing type' unless params[:chat][:type]
    raise 'missing timestamp' unless params[:chat][:timestamp]
    raise 'missing command' unless params[:command]
    @params = params
    @command = @params[:command]
    @channel = @params[:chat][:channel]
    @text_array = @params[:chat][:text].split(' ')
    search if @command[0] == 'search'
    save if @command[0] == 'save'
    hello if @command[0] == 'hello'
    status 404 if @command[0] == 'fail'
  end

  get '/info' do
    {
      help:
        {
          search: 'Search info from brain, Search for all keys: `@bot api search` - Search specific key for value: `@bot api search $key`"',
          save: 'Save info into brain: `@bot api save $key $value`',
          hello: 'Hello World Command: `@bot api hello world` returns `Hello World!`'
        }
    }.to_json
  end

  def search
    response = @command[1] ? search_key : search_hash
    attachment('Search Return', 'Search Return', response.body)
  end

  def hello
    PARTY.post(
      '/v1/speak',
      body: {
        'channel' => @channel,
        'text' => 'Hello World!'
      },
      headers: @headers
    )
    nil
  end

  def attachment(fallback, title, text)
    PARTY.post(
      '/v1/attachment',
      body: {
        'channel' => @channel,
        'attachments' =>
          {
            'fallback' => fallback,
            'title' => title,
            'text' => text
          }
      },
      headers: @headers
    )
  end

  def search_hash
    PARTY.post(
      '/v1/query_hash',
      body: {
        'plugin' => 'api'
      },
      headers: @headers
    )
  end

  def search_key
    PARTY.post(
      '/v1/query_key',
      body: {
        'plugin' => 'api',
        'key' => @command[1]
      },
      headers: @headers
    )
  end

  def save
    response = PARTY.post(
      '/v1/save',
      body: {
        'plugin' => 'api',
        'key' => @command[1],
        'value' => @command[2]
      },
      headers: @headers
    )
    attachment('Data Saved', 'Data Saved', 'Data Save Successful') if response.success?
  end
end
