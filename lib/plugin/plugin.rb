# frozen_string_literal: true
require 'yaml'
require 'docker'

# Plugin class will represent an individual plugin.
# It will check the metadata of the type of plugins to make decisions.
# It's two main functions are to:
#  1. Load the configuration of the specific plugin and load anything needed for that type.
#  2. Execute the command properly based on the type
class Plugin
  module TypeEnum
    SCRIPT = 1
    CONTAINER = 2
    API = 4
  end

  def initialize(file)
    @name = File.basename(file)
    @config = YAML.load_file(file)
  end


  def load

  end

  def exec
    # based on some meta information like the type then execute the proper way
  end

end
