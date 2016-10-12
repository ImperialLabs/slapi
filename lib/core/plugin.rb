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
  type_enum = {
    script: 'script',
    container: 'container',
    API: 'api'
  }

  def initialize(file)
    @name = File.basename(file, ".*")
    @config = YAML.load_file(file)
    @lang_settings = lang_settings
    @container = nil
    load
  end

  # Load the plugin configuration.
  # The plugin type is the important switch here.
  #
  # TODO: need a lot more error checking.
  def load
    case @config['plugin']['type']
    when 'script'
      filename = "#{@name}#{@lang_settings[:file_type]}"
      File.open("scripts/#{filename}", 'w') do |file|
        file.write(@config['plugin']['write'])
      end
      File.chmod(0777, "scripts/#{filename}")
      _image = Docker::Image.create(fromImage: @lang_settings[:image])
      config_hash = {
        name: @name,
        Image: @lang_settings[:image],
        HostConfig: {
          Binds: ["#{Dir.pwd}/scripts/#{filename}:/scripts/#{filename}"]
        },
        Cmd: ["bash", "/scripts/#{filename}"],
        Entrypoint: "/scripts/#{filename}",
        Tty: true
      }
      @container = Docker::Container.create(config_hash)
    when 'container'
      # load the docker container set in the config
      _image = Docker::Image.create(fromImage: @lang_settings[:image])
      @container = Docker::Container.create(@config[:config])
    when 'api'
      # TODO httparty config
    else
      puts "unknown plugin type configured #{@config['plugin']['type']}"
      puts "only 'script', 'container', and 'api' are known"
    end

  end

  # Execute the command sent from chat
  #
  # @param string data_from_chat
  # @return string representing response to be displayed
  def exec(data_from_chat)
    # based on some meta information like the type then execute the proper way
    case @config['plugin']['type']
    when 'script', 'container'
      @container.tap(&:start).attach(:tty => true)
      # TODO find a better way to get stdout or only last log entry? Possibly delete/recreate each time? If not, it will post the entire log into chat.
      response = @container.logs(stdout: true)
    when 'api'
      response = HTTParty.get(@config['api']['url'])
      puts response
    else
      # Error log and chat?
      # Since it will only make it to this level if the bot was invoked
      # then may it is appropriate to state that the bot does not understand?
    end
    response
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
