# frozen_string_literal: true

module Sinatra
  module SlapiRoutes
    # Sinatra Extension for Plugin Access
    # Its main functions are to:
    #  1. Allow Reloading of Plugins via API
    module Plugin
      def self.registered(slapi)
        # Handles a POST request for '/v1/reload'
        # @return [Integer] returns status 200
        slapi.post '/reload' do
          slapi.reload_plugins
          status 200
        end
      end
    end
  end
end
