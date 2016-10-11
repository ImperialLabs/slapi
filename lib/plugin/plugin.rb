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
      filename = "#{@name}#{@lang_settings[:file_type]}"
      File.open("scripts/#{filename}", 'w') do |file|
        file.write(@config['plugin']['write'])
      end
      File.chmod(0777, "scripts/#{filename}")
      #File.open( filename, "#{@config['plugin']['write']}")
      image = Docker::Image.create(fromImage: @lang_settings[:image])
      #@container = Docker::Container.create(Image: @lang_settings[:image])
      command = ["bash", "-c", "if [ -t 1 ]; then echo -n \"I'm a TTY!\"; fi"]
      config_hash = {Image: @lang_settings[:image],
                    HostConfig: {
                      Binds: ["#{Dir.pwd}/scripts/#{filename}:/scripts/#{filename}"]
                    },
                    Cmd: command,
                    Entrypoint: "/scripts/#{filename}",
                    Tty: true}
      puts "config_hash: \n\n  #{config_hash}"
      
      @container = Docker::Container.create(config_hash)
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
      #output = @container.run('ls -l')
      
      #command = ["bash", "-c", "if [ -t 1 ]; then echo -n \"I'm a TTY!\"; fi"]
      #container = Docker::Container.create('Image' => 'ubuntu', 'Cmd' => command, 'Tty' => true)
      @container.tap(&:start).attach(:tty => true)
      output = @container.logs(stdout: true)
      puts output

    when 'api'
      response = HTTParty.get(@config['api']['url'])
      puts response
    else
      # Error log and chat?
    end
    output
  end

  # TODO likely move to a helper class
  def lang_settings 
    lang = {}
    case @config['plugin']['language']
    when 'ruby', 'rb'
      lang[:file_type] = '.rb'
      #lang[:image] = 'slapi/ruby'
      lang[:image] = 'slapi/base:latest'
    when 'python', 'py'
      lang[:file_type] = '.py'
      lang[:image] = 'slapi/python'
    when 'node', 'nodejs', 'javascript', 'js'
      lang[:file_type] = '.js'
      lang[:image] = 'slapi/nodejs'
    when 'bash', 'shell'
      lang[:file_type] = '.sh'
      lang[:image] = 'slapi/base:latest'
    else
      # TODO error logging for this
      # could also use the langage sent in
      lang[:file_type] = '.sh'
      lang[:image] = 'slapi/base:latest'
    end
    lang
  end


end
