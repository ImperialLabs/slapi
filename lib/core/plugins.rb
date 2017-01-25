# frozen_string_literal: true
# require 'yaml'
require_relative 'plugin'

# Plugins class will act as a cache of the plugins currently loaded.
# It's two main functions are to:
#  1. Load the configuration of all plugins
#  2. Route the execution to the right plugin
class Plugins
  # TODO: determine if this hash is needed outside of this class
  attr_reader :plugin_hash

  def initialize(settings)
    @help_options = settings.help || {}
    @admin_options = settings.admin || {}
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
      @plugin_hash[File.basename(file, '.*')] = Plugin.new(file)
    end
  end

  # Routes the execution to the correct plugin if it exists.
  #
  # Splits off the first word it encounters and looks for a plugin with this name.
  # If the plugin exists then it send the command on.
  # If the plugin does not exist then it
  # @param Hash data
  # @return boolean - whether the command was passed on
  def exec(requested_plugin, data)
    @plugin_output = nil
    @plugin_hash.each do |name, plugin|
      @plugin_output = plugin.exec data if requested_plugin == name
    end
    @plugin_output
  end

  # Searches for phrased based plugins
  # TODO: Create Phrases for Plugins: Create code to sift through chat data to match specific phrases for plugins
  def phrase_lookup
    # search plugin hash and container labels?
  end

  # Creates primary help list
  #
  # Utilizes the bot.yml help hash to determine response level.
  # TODO: Build Help Hash/Response to return after .each
  def help(data)
    if data.text.include? ' '
      data_array = data.text.split(' ')
      # Check if data is coming from a DM or regular channel
      requested_plugin = data_array[2] unless data.channel[0] == 'D'
      requested_plugin = data_array[1] if data.channel[0] == 'D'
    end
    if requested_plugin
      help_return = ''
      @plugin_hash.each do |name, plugin|
        output = plugin.help if name == requested_plugin
        help_return += name + ':' + "\n" + output if name == requested_plugin
      end
    elsif @help_options['level'] == 1
      help_return = ''
      @plugin_hash.each do |name, _plugin|
        help_return += name + "\n"
      end
    elsif @help_options['level'] == 2
      help_return = ''
      @plugin_hash.each do |name, plugin|
        output = plugin.help
        help_return += name + ':' + "\n" + output
      end
    end
    help_return
  end

  # TODO: should this be exposed to cleanout any unused docker containers
  def cleanup_docker
    # Loop through the list of containers and plugins matching and remove any not connected
  end
end
