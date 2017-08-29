# frozen_string_literal: true

# Plugin Class Extension for API Type Plugins
class Plugin
  private

  def exec_api(data_from_chat, chat_text_array)
    response = api_response(data_from_chat, chat_text_array)

    if response.success?
      response.body unless response.body.blank?
      response.code if @settings.environment == 'test'
    else
      @logger.error("Plugin: #{@name}: returned code of #{response.code}")
      return "Error: Received code #{response.code}"
    end
  end

  def api_response(data_from_chat, chat_text_array)
    payload = api_payload(data_from_chat, chat_text_array)
    exec_url = "#{@api_url}#{@config['api_config']['endpoint']}"
    @logger.debug("Plugin: #{@name}: Exec URL is set to #{exec_url}")
    @logger.debug("Plugin: #{@name}: Exec '#{chat_text_array.drop(2)}' being sent via API")
    auth = @config.dig('plugin', 'api_config', 'basic_auth') ? @config['api_config']['basic_auth'] : false
    api_call(payload, auth, exec_url)
  end

  def api_call(payload, auth, exec_url)
    retry_count = 0
    while retry_count < 5
      begin
        response = HTTParty.post(exec_url, basic_auth: auth, body: payload, headers: @headers) if auth
        response = HTTParty.post(exec_url, body: payload, headers: @headers) unless auth
        break unless response.code.blank?
        retry_count += 1
      rescue Errno::ECONNREFUSED
        api_timeout_catch(retry_count)
        retry_count += 1
      end
    end
    response
  end

  def api_timeout_catch(count)
    raise "[ERROR] Plugin: #{@name}: Too many retries, plugin is not reachable" if count >= 5
    @logger.info("Plugin: #{@name}: connection refused; retrying in 5s...") if count < 5
    sleep 5 unless count >= 5
  end

  def api_payload(data_from_chat, chat_text_array)
    payload_build = {
      chat: {
        type: data_from_chat['type'],
        channel: data_from_chat['channel'],
        user: data_from_chat['user'],
        text: data_from_chat['text'],
        timestamp: data_from_chat['ts'],
        team: data_from_chat['team']
      },
      # Data without botname and plugin stripped leaving args
      command: chat_text_array.drop(2)
    }
    # Set Payload Type based on Content Type
    @headers.dig('Content-Type') ? content_set(payload_build) : payload_build
  end

  def content_set(payload_build)
    @headers['Content-Type'] == 'application/json' ? payload_build.to_json : payload_build
  end
end
