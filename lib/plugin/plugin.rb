# frozen_string_literal: true
require 'yaml'
require 'docker'

# Plugin class will represent an individual plugin.
# It will check the metadata of the type of plugins to make decisions.
# It's two main functions are to:
#  1. Load the configuration of the specific plugin and load anything needed for that type.
#  2. Execute the command properly based on the type
class Plugin
  
  # TODO: likely this type of numberic enum is not the right route and symbols should be used.
  # however I like the idea of the list being bound by possibilities.
  module TypeEnum
    SCRIPT = 1
    CONTAINER = 2
    API = 4
  end

  def initialize(file)
    @name = File.basename(file, ".*")
    @config = YAML.load_file(file)
    @lang_settings = lang_settings
    @container = nil
    load
  end


  # TODO: use name or label to match up with the config name
  def load
    case @config[@name]['type']
    when 'script'
      @container = Docker::Container.create(@lang_settings['image'])
    when CONTAINER
      # load the docker container set in the config
    when API
      
    else

    end
      
  end

  def exec
    # based on some meta information like the type then execute the proper way
  end

  def lang_settings 
    lang = {}
    case @config[@name]['config']['language']
    when 'ruby', 'rb'
      lang[:file_type] = '.rb'
      lang[:image] = 'slapi/ruby'
    when 'python', 'py'
      lang[:file_type] = '.py'
      lang[:image] = 'slapi/python'
    when 'node', 'nodejs', 'javascript', 'js'
      lang[:file_type] = '.js'
      lang[:image] = 'slapi/nodejs'
    when 'bash', 'shell'
      lang[:file_type] = '.sh'
      lang[:image] = 'slapi/base'
    else
      # TODO error logging for this
      # could also use the langage sent in
      lang[:file_type] = '.sh'
      lang[:image] = 'slapi/base'
    end
    lang
  end


end
