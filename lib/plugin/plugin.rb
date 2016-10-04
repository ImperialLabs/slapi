# frozen_string_literal: true
require 'yaml'
require 'docker'

# Load plugins from Yaml File
class Plugin
  def initialize(file)
    @name = File.basename(file)
    @config = YAML.load_file(file)
  end


end
