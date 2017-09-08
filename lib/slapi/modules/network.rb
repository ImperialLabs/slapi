# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'active_support/core_ext/object/blank'

# Network Helpers
# Its main functions are to:
#  1. Set the Bot IP Address based on Public and if in DIND
#  2. Exposed Ports using user provided or dynamic port assignments
module Network
  class << self
    def bot_ip(config = {})
      option = config['managed'] ? 'private' : 'public' if config['type'] == 'api'
      option = 'private' unless config['type'] == 'api'

      local_ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      public_ip = Socket.ip_address_list.detect(&:ipv4?).ip_address
      option == 'public' ? public_ip : local_ip
    end

    def plugin_ip(name, config, logger)
      container_info = Docker::Container.get(name).info
      # Builds URL based on Container Settings
      container_ip = container_info['NetworkSettings']['IPAddress'].to_s
      local_ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address

      # Determine if running via DIND/Compose Config or if running local
      compose_bot = local_ip.rpartition('.')[0] == container_ip.rpartition('.')[0]
      logger.debug(compose_bot ? "Plugin: #{name}: running inside DIND" : "Plugin: #{name}: running on local machine")

      exposed_ip = config['public'] ? local_ip : '127.0.0.1'
      # If Compose, set docker network ip. If, local use system IP set above
      compose_bot ? container_ip : exposed_ip
    end

    def expose(config)
      port = config[:ExposedPorts].keys[0].to_s.chomp('/tcp')
      expose_port = config[:ExposedPorts].present? ? port : config['app_port']
      expose_ip = config['public'] ? '0.0.0.0' : '127.0.0.1'
      exposed_port = {
        config: {
          HostConfig: {
            PortBindings: {
              "#{expose_port}/tcp" =>
              [{
                HostIp: expose_ip.to_s,
                HostPort: config['app_port']
              }]
            }
          }
        }
      }
      exposed_port
    end

    def port_find(dynamic_port)
      port_check = port_available?(dynamic_port)
      unless port_check
        dynamic_port += 1
        while port_check == false
          port_check = port_available?(dynamic_port)
          break if port_check
          dynamic_port += 1
        end
      end
      dynamic_port
    end

    def port_available?(port)
      Timeout.timeout(1) do
        begin
          TCPSocket.new('127.0.0.1', port).close
          false
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
          true
        end
      end
    rescue Timeout::Error
      true
    end
  end
end
