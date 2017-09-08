# frozen_string_literal: true

require 'logger'
require 'json'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require_relative 'modules/container'
require_relative 'modules/config'
require_relative 'modules/network'

# Slapi Brain Helper for Sinatra Extension Access
class Brain
  def initialize(settings)
    @headers = {}
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    brain_config = default_brain.with_indifferent_access if settings.brain.blank?
    brain_config = settings.brain.with_indifferent_access if settings.brain.present?
    port = Network.port_find(49230)
    ip = Network.bot_ip
    @brain_url = "http://#{ip}:#{port}"
    @name = "slapi_#{brain_config[:service]}_brain"
    default = default_config(port)
    brain_config[:container_config] = Config.merge(brain_config[:container_config], default[:container_config])
    brain_config[:container_config][:HostConfig] = Config.merge(brain_config[:container_config][:HostConfig], default[:container_config][:HostConfig])
    load(brain_config, settings)
  end

  def default_brain
    {
      service: 'redis',
      container_config: {
        Image: 'slapi/brain-redis',
        HostConfig: {
          Binds: ["#{Dir.pwd}/brain/:/data"]
        }
      }
    }
  end

  def default_config(port)
    {
      container_config: {
        name: @name,
        HostConfig: {
          PortBindings: {
            '4700/tcp' => [{ HostPort: port.to_s, HostIp: '0.0.0.0' }]
          },
          Binds: ["#{Dir.pwd}/config/#{Config.bot_file}/:/brain/bot.yml"]
        }
      }
    }
  end

  def load(brain_config, settings)
    Container.cleanup(brain_config[:container_config][:name], @logger)
    repo_info = Container.pull(brain_config[:container_config][:name], brain_config[:container_config], @logger)
    build_info = Container.build(repo_info, brain_config, @logger, settings.plugins['location'])
    brain_config[:container_config] = Container.config_merge(build_info, brain_config[:container_config])
    Container.create(brain_config[:container_config].to_hash)
    Container.start(@name)
  end

  def shutdown
    Container.cleanup(@name, @logger)
  end

  def query(hash, key = nil)
    @logger.debug("Key retrieved for #{hash}")
    body = { hash: hash, key: key }.to_json
    response = party('/query', body)
    return response.body if reponse.success?
    @logger.error("[ERROR] - Failed to query #{key}, received #{response.code} from brain") unless response.success?
  end

  def delete(hash, key)
    @logger.debug("#{key} deleted for #{hash}")
    body = { hash: hash, key: key }.to_json
    response = party('/delete', body)
    return response.body if reponse.success?
    @logger.error("[ERROR] - Failed to delete #{key} from #{hash}, received #{response.code} from brain") unless response.success?
  end

  def save(hash, key, value)
    @logger.debug("#{key} saved for #{hash}")
    body = { hash: hash, key: key, value: value }.to_json
    response = party('/save', body)
    return response.body if reponse.success?
    @logger.error("[ERROR] - Failed to save #{key} to #{hash}, received #{response.code} from brain") unless response.success?
  end

  def party(path, body)
    HTTParty.post(@brain_url + path, body: body, headers: @headers)
  end
end
