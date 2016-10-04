# frozen_string_literal: true
require 'yaml'
require 'docker'
require_relative 'plugin'

# Load plugins from Yaml File
class Plugins
  def initialize
    @yaml_files = Dir.glob(File.expand_path('../../plugins/*.yml', File.dirname(__FILE__)))
    @plugin_hash = {}
    @yaml_files.each do | file |
      plugin = Plugin.new(file)
      @plugin_hash[File.basename(file)] = plugin
    end
  end


  def load
    #@PluginLoad.each | plugin, value|
    #  pluginObject = Plugin.new(plugin)
    #end
  end


  #def exec
  #  if fails
  #end
end
