# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object'
require_relative 'helpers/container'
require_relative 'helpers/network'

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
    adapter_config = default_adapter.with_indifferent_access if settings.adapter.blank?
    adapter_config = settings.adapter.with_indifferent_access if settings.adapter.present?
    port = Network.port_find(49130)
    adapter_config.merge(default_config(adapter_config[:service], port))
    load(adapter_config)
  end

  def default_adapter
    {
      service: 'slack',
      container_config: {
        Image: 'slapi/adapter-slack'
      }
    }
  end

  def default_config(service, port)
    {
      container_config: {
        name: "slapi_#{service}_adapter",
        HostConfig: {
          "#{port}/tcp" => [{ 'HostPort' => port, 'HostIp' => '0.0.0.0' }]
        }
      }
    }
  end

  def load(adapter_config)
    Container.cleanup(adapter_config[:container_config][:name])
    Container.pull(adapter_config[:container_config][:name], adapter_config[:container_config])
    build_info = Container.build(adapter_config[:container_config][:name], adapter_config[:container_config], @logger)
    adapter_config[:container_config] = Container.config_merge(build_info[:image], adapter_config[:container_config])
    container = Container.create(adapter_config[:container_config])
    Container.start(container)
  end

  def info
    HTTParty.get('/info', headers: @headers)
  end

  def join(channel)
    body = { channel: channel }.to_json
    HTTParty.post('/join', body: body, headers: @headers)
  end

  def part(channel)
    body = { channel: channel }.to_json
    HTTParty.post('/part', body: body, headers: @headers)
  end

  def users(type, user)
    body = { type: type, user: user}.to_json
    HTTParty.post( '/users', body: body, headers: @headers )
  end

  def message(type, channel, text, user)
    body = { type: type, channel: channel, text: text, user: user }.to_json
    HTTParty.post('/messages', body: body, headers: @headers)
  end

  def rooms(type)
    body = { type: type }.to_json
    HTTParty.post('/rooms', body: body, headers: @headers)
  end

  def run
    HTTParty.post('/run', headers: @headers)
  end

  def shutdown
    HTTParty.post('/shutdown', headers: @headers)
    Container.shutdown(@container)
  end

  def party(path, body)
    HTTParty.post(@brain_url + path, body: body, headers: @headers)
  end
end
