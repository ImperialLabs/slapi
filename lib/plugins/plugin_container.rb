# frozen_string_literal: true

# Plugin Class Extension for Container Type Plugins
class Plugin
  private

  def exec_passive(exec_data)
    @logger.debug("Plugin: #{@name}: creating and sending '#{exec_data}' to passive plugin")
    @container_hash[:Cmd] = exec_data

    response = ''
    retry_count = 0
    while retry_count <= 3
      begin
        container = Docker::Container.create(@container_hash)
        @logger.debug("Plugin: #{@name}: Attaching to container")
        response = container.tap(&:start).attach(tty: true, stdout: true, logs: true)
        break unless response.blank?
        retry_count += 1
      rescue Docker::Error::TimeoutError
        @logger.debug("Plugin: #{@name}: #{retry_count >= 3 ? 'too many timeouts' : 'Exec timed out trying again'}")
      end
    end
    container.delete(force: true)
    response[0][0].to_s
  end
end
