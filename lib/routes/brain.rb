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
        # @return [String] status or message "it worked"
        slapi.post '/v1/save' do
          raise 'missing plugin name' unless params[:plugin]
          raise 'missing key' unless params[:key]
          raise 'missing value' unless params[:value]

          # Saves into brain as Plugin: plugin name (hash), key, value
          slapi.save(params[:plugin], params[:key], params[:value])
          status 200
          { 'message' => 'it worked' }.to_json
        end

        # Handles a POST request for '/v1/delete'
        #
        # @param [Hash] params the parameters sent on the request
        # @option params [String] :plugin Utilizes the plugin name as Hash Name
        # @option params [String] :key Key you wish to delete (will delete value as well)
        # @return [String] status or message "it worked"
        slapi.post '/v1/delete' do
          raise 'missing plugin name' unless params[:plugin]
          raise 'missing key' unless params[:key]

          # Saves into brain as Plugin: plugin name (hash), key
          slapi.delete(params[:plugin], params[:key])
          status 200
          { 'message' => 'it worked' }.to_json
        end

        # Handles a GET request for '/v1/key_query'
        #
        # @headers [Hash] params the parameters sent on the request
        # @option headers [String] :plugin Utilizes the plugin name as Hash Name
        # @option headers [String] :key Key you wish to query
        # @return [String] returns key value
        slapi.get '/v1/query_key' do
          raise 'missing plugin name' unless env['HTTP_PLUGIN']
          raise 'missing key' unless env['HTTP_KEY']

          # Searches brain via Plugin: plugin name (hash), key
          response = slapi.query_key(env['HTTP_PLUGIN'], env['HTTP_KEY'])
          status 200
          response
        end

        # Handles a GET request for '/v1/hash_query'
        #
        # @headers [Hash] params the parameters sent on the request
        # @option headers [String] :plugin Hash to Query for Keys (Plugin Name used as Hash Name)
        # @return [String] returns key value
        slapi.get '/v1/query_hash' do
          raise 'missing plugin name' unless env['HTTP_PLUGIN']

          # Searches brain via Plugin: plugin name (hash)
          response = slapi.query_hash(env['HTTP_PLUGIN'])
          status 200
          response
        end
      end
    end
  end
end
