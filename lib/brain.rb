# frozen_string_literal: true

require 'logger'
require 'json'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object'
require_relative 'helpers/container'
require_relative 'helpers/network'

# Slapi Brain Helper for Sinatra Extension Access
class Brain
  def initialize(settings)
    @headers = {}
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    brain_config = default_config.with_indifferent_access if settings.brain.blank?
    brain_config = settings.brain.with_indifferent_access if settings.brain.present?
    load(brain_config)
  end

  def default_config
    {
      service: 'redis',
      container_config: {
        name: 'slapi_brain',
        Image: 'redis:3-alpine:latest',
        Cmd: ['redis-server', '--appendonly', 'yes'],
        HostConfig: {
          '6379/tcp' => [{ 'HostPort' => '6379', 'HostIp' => '0.0.0.0' }],
          Binds: ["#{Dir.pwd}/brain/:/data"]
        }
      }
    }
  end

  def load(brain_config)
    Container.cleanup(brain_config[:container_config][:name])
    Container.pull(brain_config[:container_config][:name], brain_config[:container_config])
    build_info = Container.build(brain_config[:container_config][:name], brain_config[:container_config], @logger)
    brain_config[:container_config] = Container.config_merge(build_info[:image], brain_config[:container_config])
    container = Container.create(brain_config[:container_config])
    Container.start(container)
  end

  def shutdown
    Container.shutdown(@container)
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