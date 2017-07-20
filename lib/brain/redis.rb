# frozen_string_literal: true
require 'socket'
require 'logger'
require 'json'
require 'yaml'
require 'docker'
require 'redis'

# Brain Class
# Its main functions are to:
#  1. Create Redis Container
#     - Local Docker Install or DIND depending on Setup
#     - Validates if a previous container is running and replaces it
#     - Mounts Path to DIND Host or Localhost for Redis AOF file (Data Persistance)
#  2. Create Redis Client Access
#     - URL For Redis determined by IP Comparison (Checking for Compose Environment)
#  3. Enables Access to Brain
#     - Query brain for specific key (i.e. Plugin User)
#     - Query brain for specific hash (i.e. Plugin)
#     - Delete Key from Brain (i.e. Plugin User)
#     - Save Key/Value to Brain (i.e. Plugin User Bob )
class Brain
  def initialize(settings)
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    brain
  end

  def brain
    brain_check('slapi_brain')
    container_hash = { name: 'slapi_brain', HostConfig: {} }
    @image = Docker::Image.create(fromImage: 'redis:3-alpine')
    container_hash['Entrypoint'] = @image.info['Config']['Entrypoint']
    container_hash['WorkingDir'] = @image.info['Config']['WorkingDir']
    container_hash['Labels'] = @image.info['Config']['Labels']
    container_hash[:Image] = 'redis:3-alpine'
    container_hash[:Cmd] = ['redis-server', '--appendonly', 'yes']
    container_hash[:HostConfig][:PortBindings] = { '6379/tcp' => [{ 'HostPort' => '6379', 'HostIp' => '0.0.0.0' }] }
    container_hash[:HostConfig][:Binds] = ["#{Dir.pwd}/brain/:/data"]
    container = Docker::Container.create(container_hash)
    container.tap(&:start)
    container_info = Docker::Container.get('slapi_brain').info
    @redis = Redis.new(url: url_set(container_info))
  end

  # def brain_check(name)
  #   container = Docker::Container.get(name)
  #   container&.delete(force: true) if container
  # rescue StandardError => _error
  #   false
  # end

  def query_key(hash_name, key)
    @logger.debug("Key retrieved for #{hash_name}")
    @redis.hmget(hash_name, key)
  end

  def query_hash(hash_name)
    @logger.debug("Hash retrieved for #{hash_name}")
    @redis.hkeys(hash_name)
  end

  def delete(hash_name, key)
    @logger.debug("Data deleted for #{hash_name}")
    @redis.hdel(hash_name, key)
  end

  def save(hash_name, key, value)
    @logger.debug("Data saved for #{hash_name}")
    @redis.hmset(hash_name, key, value)
  end

  def url_set(container_info)
    # Pull local IP and Brain Contianer IP
    local_ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
    container_ip = container_info['NetworkSettings']['IPAddress']

    # Determine if running via DIND/Compose Config or if running local
    compose_bot = local_ip.rpartition('.')[0] == container_ip.rpartition('.')[0]
    @logger.debug(compose_bot ? 'Brain: running inside DIND' : 'Brain: running on local machine')
    # If Compose, set docker network ip. If, local use localhost
    compose_bot ? "redis://#{container_ip}:6379" : "redis://#{local_ip}:6379"
  end
end
