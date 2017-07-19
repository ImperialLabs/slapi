# frozen_string_literal: true

module Sinatra
  module SlapiRoutes
    # Sinatra Extension for Adapter Access
    # Its main functions are to:
    #  1. Allow Message Forwarding from Chat Adapter
    module Adapter
      def self.registered(slapi)
        # Handles a POST request for '/v1/messages'
        # @return [Integer] returns status 200 if succesful
        slapi.post '/v1/messages' do
          begin
            slapi.listener(JSON.parse(params))
            status 200
          rescue => e
            status 500
            body "[ERROR] - Received #{e}"
            @logger.error("[ERROR] - Received #{e}")
          end
        end
      end
    end
  end
end
