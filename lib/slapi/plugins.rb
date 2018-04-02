# frozen_string_literal: true

require 'yaml'
require_relative 'plugins/plugin'
require_relative 'modules/network'

# Plugins class will act as a cache of the plugins currently loaded.
# Its two main functions are to:
#  1. Load the configuration of all plugins
#  2. Route the execution to the right plugin
class Plugins
  include GC
  attr_reader :plugin_hash

  def initialize(settings)
    @plugin_hash = {}
    @settings = settings
    load
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
      dynamic_port = Network.port_find(port_start)
      @plugin_hash[File.basename(file, '.*')] = Plugin.new(file, dynamic_port, @settings)
      port_start = dynamic_port + 1
    end
  end

  def reload
    garbage_collect
    load
  end

  # Routes the execution to the correct plugin if it exists.
  def help_list(plugin = nil)
    help_return = ''
    if plugin
      help_return += plugin + ':' + "\n" + @plugin_hash[plugin].help
    else
      help_return += "ping:   check the bot\nhelp:   show this help\nreload:   reload all plugins\n"
      @plugin_hash.each do |name, plugin|
        description = plugin.plugin_config['description'] ? plugin.plugin_config['description'] : ''
        help_return += @settings.help['level'] == 1 ? name + ':   ' + description + "\n" : name + ':   ' + description + "\n" + plugin.help
      end
    end
    help_return
  end

  # Routes the execution to the correct plugin
  def exec(data, client_id, plugin = nil)
    @plugin_hash[plugin]&.exec(client_id, data)
  end

  # Verifies plugin that's being executed
  def verify(plugin)
    @plugin_hash[plugin]
  end
end
