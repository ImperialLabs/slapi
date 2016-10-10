# frozen_string_literal: true
require 'yaml'
require 'docker'
require 'httparty'

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
    case @config['plugin']['type']
    when 'script'
      filename = "scripts/#{@name}#{@lang_settings[:file_type]}"
      File.open( filename, "#{@config['plugin']['write']}")
      Docker::Image.create(fromImage: @lang_settings[:image])
      #@container = Docker::Container.create(Image: @lang_settings[:image])
      @container = Docker::Container.create(Image: @lang_settings[:image],
                                            Volumes: ["/scripts/#{filename}:/scripts/#{filename}"],
                                            Entrypoint: "/scripts/#{filename}",
                                            Tty: true)
    when 'container'
      # load the docker container set in the config
      @container = Docker::Container.create(@config[:config])
    when 'api'
      # TODO httparty config
    else

    end

  end

  # Execute the command sent from chat
  #
  # @param string data_from_chat
  # @return boolean representing Success/Failure
  def exec(data_from_chat)
    # based on some meta information like the type then execute the proper way
    case @config['plugin']['type']
    when 'script', 'container'
      #output = @container.run([data_from_chat])
      output = @container.run('ls -1', 10)
      puts output
    when 'api'
      response = HTTParty.get(@config['api']['url'])
      puts response
    else
      # Error log and chat?
    end
    output
  end

  # TODO
  def lang_settings
    lang = {}
    case @config['plugin']['language']
    when 'ruby', 'rb'
      lang[:file_type] = '.rb'
      #lang[:image] = 'slapi/ruby'
      lang[:image] = 'ubuntu'
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
