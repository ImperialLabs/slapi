# frozen_string_literal: true

# Network Helpers for Plugin Class
# Its main functions are to:
#  1. Set the Bot IP Address based on Public and if in DIND
#  2. Exposed Ports using user provided or dynamic port assignments
class Plugin
  def bot_ip
    option = @config['managed'] ? 'private' : 'public' if @config['type'] == 'api'
    option = 'private' unless @config['type'] == 'api'

    local_ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
    public_ip = Socket.ip_address_list.detect(&:ipv4?).ip_address
    @bot_ip = option == 'public' ? public_ip : local_ip
  end

  def plugin_ip
    container_info = Docker::Container.get(@name).info
    # Builds URL based on Container Settings
    container_ip = container_info['NetworkSettings']['IPAddress'].to_s
    local_ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address

    # Determine if running via DIND/Compose Config or if running local
    compose_bot = local_ip.rpartition('.')[0] == container_ip.rpartition('.')[0]
    @logger.debug(compose_bot ? "Plugin: #{@name}: running inside DIND" : "Plugin: #{@name}: running on local machine")

    exposed_ip = @config['public'] ? local_ip : '127.0.0.1'
    # If Compose, set docker network ip. If, local use system IP set above
    @plugin_ip = compose_bot ? container_ip : exposed_ip
  end

  def expose
    expose_ip = @config['public'] ? '0.0.0.0' : '127.0.0.1'
    container_port = @container_hash[:ExposedPorts].keys[0].to_s
    @config['app_port'] = container_port.chomp('/tcp') if @config['app_port'].blank?
    exposed_port = {
      HostConfig: {
        PortBindings: {
          "#{@config['app_port']}/tcp" =>
          [{
            HostIp: expose_ip.to_s,
            HostPort: @config['exposed_port'].to_s
          }]
        }
      }
    }
    @container_hash.merge!(exposed_port)
  end
end
