# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'

# Adapter Class
# Its main functions are to:
#  1. Load Chat Adapter
#     - Find adapter in config
#     - Pull adapter container and load
class Adapter
  def initialize(settings)
    @headers = {}
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
  end

  def info
    HTTParty.get(
      '/info',
      headers: @headers
    )
  end

  def join(channel)
    body = {
      channel: channel
    }.to_json

    HTTParty.post(
      '/join',
      body: body,
      headers: @headers
    )
  end

  def part(channel)
    body = {
      channel: channel
    }.to_json

    HTTParty.post(
      '/part',
      body: body,
      headers: @headers
    )
  end

  def users(type, user)
    body = {
      type: type,
      user: user
    }.to_json

    HTTParty.post(
      '/users',
      body: body,
      headers: @headers
    )
  end

  def message(type, channel, text, user)
    body = {
      type: type,
      channel: channel,
      text: text,
      user: user
    }.to_json

    HTTParty.post(
      '/messages',
      body: body,
      headers: @headers
    )
  end

  def rooms(type)
    body = {
      type: type
    }.to_json

    HTTParty.post(
      '/rooms',
      body: body,
      headers: @headers
    )
  end

  def run
    HTTParty.post(
      '/run',
      headers: @headers
    )
  end

  def shutdown
    HTTParty.post(
      '/shutdown',
      headers: @headers
    )
  end
end
