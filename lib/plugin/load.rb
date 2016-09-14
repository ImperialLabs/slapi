# frozen_string_literal: true
require 'yaml'
require 'docker'

# Load plugins from Yaml File
class Plugins
  plugins = YAML.load_file('../../plugin.yml')

  # Parse out plugins and determine plugin type, then utilize proper class to configure that plugin setup.
end
