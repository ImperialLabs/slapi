# frozen_string_literal: true

require 'logger'
require 'json'
require 'yaml'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require_relative 'modules/container'
require_relative 'modules/config'
require_relative 'modules/network'

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
    adapter_config = default_adapter(settings.port).with_indifferent_access if settings.adapter.blank?
    adapter_config = settings.adapter.with_indifferent_access if settings.adapter.present?
    adapter_config.merge!(default_adapter(settings.port)) if settings.adapter['service'] == 'slack'
    port = Network.port_find(49130)
    ip = Network.bot_ip
    @adapter_url = "http://#{ip}:#{port}"
    @name = "slapi_#{adapter_config[:service]}_adapter"
    default = default_config(port)
    adapter_config[:container_config] = Config.merge(adapter_config[:container_config], default[:container_config])
    load(adapter_config, settings)
  end

  def default_adapter(port)
    {
      service: 'slack',
      container_config: {
        Image: 'slapi/adapter-slack',
        Tty: true,
        Env: ["BOT_URL=#{Network.bot_ip}:#{port}"]
      }
    }
  end

  def default_config(port)
    {
      container_config: {
        name: @name,
        HostConfig: {
          PortBindings: {
            '4700/tcp' => [{ 'HostPort' => port.to_s, 'HostIp' => '0.0.0.0' }]
          },
          Binds: ["#{Dir.pwd}/config/#{Config.bot_file}:/adapter/bot.yml"]
        }
      }
    }
  end

  def load(adapter_config, settings)
    Container.cleanup(adapter_config[:container_config][:name], @logger)
    repo_info = Container.pull(adapter_config[:container_config][:name], adapter_config[:container_config], @logger)
    build_info = Container.build(repo_info, adapter_config, @logger, settings.plugins['location'])
    adapter_config[:container_config] = Container.config_merge(build_info, adapter_config[:container_config])
    Container.create(adapter_config[:container_config].to_hash)
    Container.start(@name)
  end

  def info(retry_count)
    response = OpenStruct.new(body: nil)
    while retry_count < 5
      begin
        response = HTTParty.get(@adapter_url + '/info', headers: @headers, timeout: 10)
        if response.success? && response.body.present?
          info = JSON.parse(response)
          break
        end
      rescue StandardError
        sleep(5)
        retry_count += 1
        @logger.error("Plugin: #{@name}: No info endpoint or no data") if retry_count >= 5
      end
    end
    info
  end

  def join(channel)
    body = { channel: channel }
    party('post', '/join', body)
  end

  def part(channel)
    body = { channel: channel }
    party('post', '/part', body)
  end

  def users(type, user)
    body = { type: type, user: user }
    party('post', '/users', body)
  end

  def message(type, channel, text, user = nil)
    body = { type: type, channel: channel, text: text, user: user }
    send_message(body)
  end

  def formatted(channel, attachment)
    body = { type: 'formatted', channel: channel, attachment: attachment }
    send_message(body)
  end

  def send_message(body)
    party('post', '/messages', body)
  end

  def rooms(type)
    body = { type: type }
    party('post', '/rooms', body)
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
      HTTParty.get(@adapter_url + path, headers: @headers)
    end
  end
end
