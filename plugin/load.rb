require 'yaml'

plugins = YAML.load_file('plugin.yml')


# Parse out plugins and determine plugin type, then utilize proper class to configure that plugin setup.

