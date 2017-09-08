# frozen_string_literal: true

require 'logger'
require 'sterile'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require_relative 'container'

# Exec Module
# Its main functions are to:
#  1. Sterlize data from chat
#  2. Set data passed to plugin based on data type set
module Exec
  class << self
    def sterilize(data)
      clean_text = data[:text].sterilize
      data[:text] = clean_text
      data
    end

    def data_type(plugin_config, data_from_chat, chat_text_array, client_id)
      data_convert = data_from_chat.to_h
      bot_name = data_from_chat[:text].include?(client_id)
      simple_data = bot_name ? chat_text_array.drop(2) : chat_text_array.drop(1)
      plugin_config['data_type'] == 'all' ? data_convert.to_json : simple_data
    end

    def split(data_from_chat)
      data_from_chat[:text].split(/\s(?=(?:[^"]|"[^"]*")*$)/)
    end

    def passive(plugin_config, exec_data, logger)
      logger.debug("Plugin: #{plugin_config[:config]['name']}: creating and sending '#{exec_data}' to passive plugin")
      plugin_config[:config][:Cmd] = exec_data

      response = ''
      retry_count = 0
      while retry_count <= 3
        begin
          logger.debug("Plugin: #{plugin_config[:config]['name']}: Attaching to container")
          response = Container.start(plugin_config[:config]['name'], true, plugin_config)
          break unless response.blank?
          Container.cleanup(plugin_config[:config]['name'], logger)
          retry_count += 1
        rescue Docker::Error::TimeoutError
          logger.debug("Plugin: #{plugin_config[:config]['name']}: #{retry_count >= 3 ? 'too many timeouts' : 'Exec timed out trying again'}")
        end
      end
      Container.cleanup(plugin_config[:config]['name'], logger)
      response[0][0].to_s
    end

    def active(plugin_config, exec_data, logger)
      logger.debug("Plugin: #{plugin_config[:config]['name']}: Sending '#{exec_data}' to active plugin")
      exec_array = plugin_config[:config]['command'].split(' ')
      exec_array.push(exec_data)
      response = Container.exec(plugin_config[:config]['name'], exec_array)
      response[0][0].to_s
    end

    def api(plugin_config, data_from_chat, chat_text_array, logger)
      response = api_response(plugin_config, data_from_chat, chat_text_array, logger)
      if response.success?
        response.body unless response.body.blank?
        response.code if @settings.environment == 'test'
      else
        logger.error("Plugin: #{plugin_config[:config]['name']}: returned code of #{response.code}")
        return "Error: Received code #{response.code}"
      end
    end

    private

    def api_response(plugin_config, data_from_chat, chat_text_array, logger)
      payload = api_payload(data_from_chat, chat_text_array, plugin_config)
      exec_url = "#{@api_url}#{plugin_config['api_config']['endpoint']}"
      logger.debug("Plugin: #{plugin_config[:config]['name']}: Exec URL is set to #{exec_url}")
      logger.debug("Plugin: #{plugin_config[:config]['name']}: Exec '#{chat_text_array.drop(2)}' being sent via API")
      auth = @config.dig('plugin', 'api_config', 'basic_auth') ? plugin_config['api_config']['basic_auth'] : false
      api_call(payload, auth, exec_url, plugin_config, logger)
    end

    def api_payload(data_from_chat, chat_text_array, plugin_config)
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
      plugin_config.api_config['headers'].dig('Content-Type') ? content_set(payload_build, plugin_config) : payload_build
    end

    def api_call(payload, auth, exec_url, plugin_config, logger)
      retry_count = 0
      while retry_count < 5
        begin
          response = HTTParty.post(exec_url, basic_auth: auth, body: payload, headers: plugin_config[:api_config]['headers']) if auth
          response = HTTParty.post(exec_url, body: payload, headers: plugin_config[:api_config]['headers']) unless auth
          break unless response.code.blank?
          retry_count += 1
        rescue Errno::ECONNREFUSED
          api_timeout_catch(retry_count, logger)
          retry_count += 1
        end
      end
      response
    end

    def api_timeout_catch(count, logger)
      raise "[ERROR] Plugin: #{plugin_config[:config]['name']}: Too many retries, plugin is not reachable" if count >= 5
      logger.info("Plugin: #{plugin_config[:config]['name']}: connection refused; retrying in 5s...") if count < 5
      sleep 5 unless count >= 5
    end

    def content_set(payload_build, plugin_config)
      plugin_config[:api_config]['headers']['Content-Type'] == 'application/json' ? payload_build.to_json : payload_build
    end
  end
end
