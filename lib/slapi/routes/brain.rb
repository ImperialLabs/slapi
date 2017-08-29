# frozen_string_literal: true

require 'sinatra'

module Sinatra
  module SlapiRoutes
    # Brain Routes
    # Its main functions are to:
    #  1. Allow quering of Redis Database
    #     - Query by Hash (aka Redis Key)
    #     - Query by Key (aka Redis Field)
    #  2. Enables saving data to Brain
    #  3. Enables delete data from Brain
    module Brain
      def self.registered(slapi)
        # Handles a POST request for '/v1/save'
        #
        # @param [Hash] params the parameters sent on the request
        # @option params [String] :plugin Utilizes the plugin name as Hash Name
        # @option params [String] :key Key inside of Hash
        # @option params [String] :value Value being saved into brain
        # @return [Integer] status
        slapi.post '/v1/save' do
          raise 'missing plugin name' unless params[:hash]
          raise 'missing key' unless params[:key]
          raise 'missing value' unless params[:value]

          # Saves into brain as Plugin: plugin name (hash), key, value
          begin
            slapi.bot.brain.save(params[:hash], params[:key], params[:value])
            status 200
          rescue => e
            status 500
            body "[ERROR] - Received #{e}"
            @logger.error("[ERROR] - Received #{e}")
          end
        end

        # Handles a POST request for '/v1/delete'
        #
        # @param [Hash] params the parameters sent on the request
        # @option params [String] :plugin Utilizes the plugin name as Hash Name
        # @option params [String] :key Key you wish to delete (will delete value as well)
        # @return [Integer] status
        slapi.post '/v1/delete' do
          raise 'missing plugin name' unless params[:hash]
          raise 'missing key' unless params[:key]

          # Saves into brain as Plugin: plugin name (hash), key
          begin
            slapi.bot.brain.delete(params[:hash], params[:key])
            status 200
          rescue => e
            status 500
            body "[ERROR] - Received #{e}"
            slapi.logger.error("[ERROR] - Received #{e}")
          end
        end

        # Handles a GET request for '/v1/key_query'
        #
        # @headers [Hash] params the parameters sent on the request
        # @option headers [String] :plugin Utilizes the plugin name as Hash Name
        # @option headers [String] :key Key you wish to query
        # @return [Integer] returns status 200
        # @return [String] returns key value
        slapi.post '/v1/query' do
          raise 'missing plugin name' unless params[:hash]
          raise 'missing key' unless params[:key]

          # Searches brain via Plugin: plugin name (hash), key
          begin
            if params[:key]
              body slapi.bot.brain.query(params[:hash], params[:key])
            else
              body slapi.bot.brain.query(params[:hash])
            end
            status 200
          rescue => e
            status 500
            body "[ERROR] - Received #{e}"
            slapi.logger.error("[ERROR] - Received #{e}")
          end
        end
      end
    end
  end
end
