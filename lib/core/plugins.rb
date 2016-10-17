# frozen_string_literal: true
#require 'yaml'
require_relative 'plugin'

# Plugins class will act as a cache of the plugins currently loaded.
# It's two main functions are to:
#  1. Load the configuration of all plugins
#  2. Route the execution to the right plugin
class Plugins
  # TODO: determine if this hash is needed outside of this class
  attr_reader :plugin_hash

  def initialize
    @plugin_hash = {}
    load
  end

  # Loads the plugin configuration.
  # Intention is that this is called on startup, however can also be called at any time
  # during execution to reload
  #
  # Currently does not take any parameters nor does it return anything.
  # Future iterations should allow for configuration based on commands from chat.
  def load
    # TODO: Should this remove all images
    # TODO: Should this remove all untagged images?
    #
    # TODO: play with where we want the plugin configuration to live.
    yaml_files = File.expand_path('../../config/plugins/*.yml', File.dirname(__FILE__))
    Dir.glob(yaml_files).each do |file|
      @plugin_hash[File.basename(file, ".*")] = Plugin.new(file)
    end
  end

  # Routes the execution to the correct plugin if it exists.
  #
  # Splits off the first word it encounters and looks for a plugin with this name.
  # If the plugin exists then it send the command on.
  # If the plugin does not exist then it
  # @param Hash data
  # @return boolean - whether the command was passed on
  def exec(data)
    # if contains a space
    if data.text.include? ' '
      bot_name = data.text.match(" ").pre_match
      command = data.text.match(" ").post_match
      requested_plugin = command.match(" ").pre_match
      @plugin_hash.each do |name, plugin|
        if name == requested_plugin
          # TODO: may need to either:
          #   return the return from plugin.exec
          #   or make a call through the API to post in the channel
          output = plugin.exec command.match(" ").post_match
          return output
        end
      end
    end
    nil
  end

  # Searches for phrased based plugins
  def phrase_lookup
    # search plugin hash and container labels?
  end

  # Creates primary help list
  #
  # Utilizes the bot.yml help hash to determine response level.
  def help
    # Merge all hashes together or parse out a file(s)?
  end


  # TODO should this be exposed to cleanout any unused docker containers
  def cleanup_docker
    # Loop through the list of containers and plugins matching and remove any not connected
  end

end
