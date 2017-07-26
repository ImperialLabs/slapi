# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object'
require_relative 'helpers/container'
require_relative 'helpers/config'
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
    ip = Network.bot_ip
    @adapter_url = "#{ip}:#{port}"
    default = default_config(adapter_config[:service], port)
    adapter_config[:container_config] = Config.merge(adapter_config[:container_config], default)
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
          '4700/tcp' => [{ 'HostPort' => port, 'HostIp' => '0.0.0.0' }],
          Binds: ["#{Dir.pwd}/../config/#{Config.bot_file}/:/brain/bot.yml"]
        }
      }
    }
  end

  def load(adapter_config)
    container_config = adapter_config[:container_config]
    Container.cleanup(container_config[:name])
    Container.pull(container_config[:name], container_config)
    build_info = Container.build(container_config[:name], container_config, @logger)
    adapter_config[:container_config] = Container.config_merge(build_info[:image], container_config)
    container = Container.create(adapter_config[:container_config])
    Container.start(container)
  end

  def info
    party('get', '/info')
  end

  def join(channel)
    body = { channel: channel }.to_json
    party('post', '/join', body: body)
  end

  def part(channel)
    body = { channel: channel }.to_json
    party('post', '/part', body: body)
  end

  def users(type, user)
    body = { type: type, user: user }.to_json
    party('post', '/users', body: body)
  end

  def message(type, channel, text, user = nil)
    body = { type: type, channel: channel, text: text, user: user }.to_json
    send_message(body)
  end

  def formatted(channel, attachment)
    body = { type: 'formatted', channel: channel, attachment: attachment }.to_json
    send_message(body)
  end

  send_message(body)
    party('post', '/messages', body: body)
  end

  def rooms(type)
    body = { type: type }.to_json
    party('post', '/rooms', body: body)
  end

  def run
    party('post', '/run')
  end

  def shutdown
    party('post', '/shutdown')
    Container.shutdown(@container)
  end

  def party(type, path, body = nil)
    case type
    when 'post'
      HTTParty.post(@adapter_url + path, body: body, headers: @headers)
    when 'get'
      HTTParty.post(@adapter_url + path, headers: @headers)
    end
  end
end
