# frozen_string_literal: true

require 'logger'
require 'yaml'
require_relative 'plugin'
require_relative 'modules/network'

# Plugins class will act as a cache of the plugins currently loaded.
# Its two main functions are to:
#  1. Load the configuration of all plugins
#  2. Route the execution to the right plugin
class Plugins
  attr_reader :plugin_hash

  def initialize(settings)
    @plugin_hash = {}
    @settings = settings
    @logger = Logger.new(STDOUT)
    @logger.level = settings.logger_level
    @network = Network.new
  end

  # Loads the plugin configuration.
  # Intention is that this is called on startup, however can also be called at any time
  # during execution to reload
  #
  # Currently does not take any parameters nor does it return anything.
  # Future iterations should allow for configuration based on commands from chat.
  def load
    file_location = @settings.plugins['location'] ? @settings.plugins['location'] : '../../config/plugins/'
    yaml_files = File.expand_path(file_location + '*.yml', File.dirname(__FILE__))
    port_start = 48130
    Dir.glob(yaml_files).each do |file|
      dynamic_port = @network.port_find(port_start)
      @plugin_hash[File.basename(file, '.*')] = Plugin.new(file, dynamic_port, @settings)
      port_start = dynamic_port + 1
    end
  end

  def reload
    @plugin_hash.garbage_collect
    load
  end

  # Routes the execution to the correct plugin if it exists.
  def help_list(requested_plugin = nil)
    help_return = ''
    if requested_plugin
      help_return += requested_plugin + ':' + "\n" + @plugin_hash[requested_plugin].help
    else
      help_return += "ping:   check the bot\nhelp:   show this help\nreload:   reload all plugins\n"
      @plugin_hash.each do |name, plugin|
        description = plugin.config['description'] ? plugin.config['description'] : ''
        help_return += @settings.help['level'] == 1 ? name + ':   ' + description + "\n" : name + ':   ' + description + "\n" + plugin.help
      end
    end
    help_return
  end

  # Routes the execution to the correct plugin
  def exec(data, client_id, requested_plugin = nil)
    @plugin_hash[requested_plugin]&.exec(client_id, data)
  end

  # Verifies plugin that's being executed
  def verify(requested_plugin)
    @plugin_hash[requested_plugin]
  end
end
