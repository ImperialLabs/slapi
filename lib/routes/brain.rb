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
          raise 'missing plugin name' unless params[:plugin]
          raise 'missing key' unless params[:key]
          raise 'missing value' unless params[:value]

          # Saves into brain as Plugin: plugin name (hash), key, value
          slapi.save(params[:plugin], params[:key], params[:value])
          status 200
        end

        # Handles a POST request for '/v1/delete'
        #
        # @param [Hash] params the parameters sent on the request
        # @option params [String] :plugin Utilizes the plugin name as Hash Name
        # @option params [String] :key Key you wish to delete (will delete value as well)
        # @return [Integer] status
        slapi.post '/v1/delete' do
          raise 'missing plugin name' unless params[:plugin]
          raise 'missing key' unless params[:key]

          # Saves into brain as Plugin: plugin name (hash), key
          slapi.delete(params[:plugin], params[:key])
          status 200
        end

        # Handles a GET request for '/v1/key_query'
        #
        # @headers [Hash] params the parameters sent on the request
        # @option headers [String] :plugin Utilizes the plugin name as Hash Name
        # @option headers [String] :key Key you wish to query
        # @return [Integer] returns status 200
        # @return [String] returns key value
        slapi.post '/v1/query_key' do
          raise 'missing plugin name' unless params[:plugin]
          raise 'missing key' unless params[:key]

          # Searches brain via Plugin: plugin name (hash), key
          response = slapi.query_key(params[:plugin], params[:key])
          status 200
          body response
        end

        # Handles a GET request for '/v1/hash_query'
        #
        # @headers [Hash] params the parameters sent on the request
        # @option headers [String] :plugin Hash to Query for Keys (Plugin Name used as Hash Name)
        # @return [Integer] returns status 200
        # @return [String] returns hash keys
        slapi.post '/v1/query_hash' do
          raise 'missing plugin name' unless params[:plugin]

          # Searches brain via Plugin: plugin name (hash)
          response = slapi.query_hash(params[:plugin])
          status 200
          body response
        end
      end
    end
  end
end
