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
      image = Docker::Image.create('fromImage' => 'ubuntu:14.04')
      @container = Docker::Container.create(Image: @lang_settings[:image])
      @container = Docker::Container.create(Image: @lang_settings[:image], 'Cmd' => @config[@name]['config']['run'], 'Tty' => true)
    when 'container'
      # load the docker container set in the config
      @container = Docker::Container.create(@config[:config])
    when 'api'
      
    else

    end
      
  end

  # Execute the command sent from chat
  #
  # @param string data_from_chat
  # @return boolean representing Success/Failure
  def exec(data_from_chat)
    # based on some meta information like the type then execute the proper way
    case @config[@name]['type']
    when 'script', 'container'
      @container.run([data_from_chat])
    when 'api'
      response = HTTParty.get(@config['api']['url'])
      puts response
    else
      # Error log and chat?
    end
  end

  # TODO 
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
      lang[:image] = 'ubuntu'
    else
      # TODO error logging for this
      # could also use the langage sent in
      lang[:file_type] = '.sh'
      lang[:image] = 'slapi/base'
    end
    lang
  end


end
