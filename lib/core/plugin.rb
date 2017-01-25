# frozen_string_literal: true
require 'yaml'
require 'docker'
require 'httparty'
require 'json'

# Plugin class will represent an individual plugin.
# It will check the metadata of the type of plugins to make decisions.
# It's two main functions are to:
#  1. Load the configuration of the specific plugin and load anything needed for that type.
#  2. Execute the command properly based on the type
class Plugin
  # TODO: likely this type of numberic enum is not the right route and symbols should be used.
  # however I like the idea of the list being bound by possibilities.
  _type_enum = {
    script: 'script',
    container: 'container',
    API: 'api'
  }

  def initialize(file)
    @name = File.basename(file, '.*')
    @config = YAML.load_file(file)
    @lang_settings = lang_settings
    @container = nil
    @container_info = {}
    @api_info = {}
    @container_hash = { 'name' => @name }
    @help_hash = {}
    load
  end

  # Keeping DRY, all repetive load tasks go here.
  def load_docker(filename = nil)
    clear_existing_container(@name)
    case @config['plugin']['type']
    when 'script'
      @image = Docker::Image.create(fromImage: @lang_settings[:image])
      @container_hash = {
        'Image' => @lang_settings[:image],
        'HostConfig' => {
          'Binds' => ["#{Dir.pwd}/scripts/#{filename}:/scripts/#{filename}"]
        },
        'Entrypoint' => "/scripts/#{filename}",
        'Tty' => true
      }
      @container_hash['Labels'] = @config['plugin']['help']
    when 'container'
      @image = Docker::Image.create(fromImage: @config['plugin']['config']['Image'])
      @container_hash['Entrypoint'] = @image.info['Config']['Entrypoint']
      @container_hash['WorkingDir'] = @image.info['Config']['WorkingDir']
      @container_hash['Labels'] = @image.info['Config']['Labels']
      @config['plugin']['config'].each do |key, value|
        @container_hash[key] = value
      end
    end
  end

  def write_script(filename)
    File.open("scripts/#{filename}", 'w') do |file|
      file.write(@config['plugin']['write'])
    end
    File.chmod(0777, "scripts/#{filename}")
  end

  def load_passive
    # placeholder
    nil
  end

  def load_active
    unless @config['plugin']['mount_config'].nil?
      @config['plugin']['config']['HostConfig']['Binds'] = ["#{Dir.pwd}/config/plugins/#{@name}.yml:#{@config['plugin']['mount_config']}"]
    end
    @container = Docker::Container.create(@container_hash)
    @container.start
    @container_info = @container.info
  end

  def load_api
    # TODO: Add API Loading Config
    # @headers = {
    #   'Content-Type' => @config['plugin']['api']['content_type'],
    #   'Authorization' => @config['plugin']['api']['auth']
    # }
  end

  # Load the plugin configuration.
  # The plugin type is the important switch here.
  #
  # TODO: need a lot more error checking.
  def load
    case @config['plugin']['type']
    when 'script'
      filename = "#{@name}#{@lang_settings[:file_type]}"
      load_docker(filename)
      write_script(filename)
      # NOTE: The use of hash rockets is intentional
      # see: https://github.com/swipely/docker-api/issues/360 and https://github.com/swipely/docker-api/pull/365
    when 'container'
      # load the docker container set in the config
      load_docker
      case @config['plugin']['listen_type']
      when 'passive'
        load_passive
      when 'active'
        load_active
      end
    when 'api'
      load_api
    else
      puts "unknown plugin type configured #{@config['plugin']['type']}"
      puts "only 'script', 'container', and 'api' are known"
    end
    help_load
  end

  # Build out help commands for users to query in chat
  def help_load
    @help_list = ''
    if @container_hash['Labels']
      @container_hash['Labels'].each do |label, desc|
        @help_list += '    ' + label + ' : ' + desc + "\n"
      end
    elsif @api_info.key? :Help
      @api_info['help'].each do |arg, desc|
        @help_list += '    ' + arg + ' : ' + desc + "\n"
      end
    elsif @config['plugin']['help']
      @config['plugin']['help'].each do |arg, desc|
        @help_list += '    ' + arg + ' : ' + desc + "\n"
      end
    else
      puts @name + ': no labels or help info found'
    end
  end

  def help
    @help_list
  end

  # Execute the command sent from chat
  #
  # @param string data_from_chat
  # @return string representing response to be displayed
  def exec(data_from_chat = nil)
    # based on some meta information like the type then execute the proper way
    # Strip an incorrection coded qoutes to UTF8 ones
    data_from_chat.text.tr!('“', '"')
    # Split chat data after @bot plugin into args to pass into plugin.
    # Split args based on qoutes, args are based on spaces unless in qoutes
    chat_text_array = data_from_chat.text.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
    exec_data = chat_text_array.drop(2) unless @config['plugin']['data_type'] == 'all'
    exec_data = data_from_chat.to_json if @config['plugin']['data_type'] == 'all'
    case @config['plugin']['type']
    when 'script', 'container'
      case @config['plugin']['listen_type']
      when 'passive'
        # Will mount the plugins yml file into the container at specified path.
        # This enable configing the plugin with a single file at both level (SLAPI and Self)
        unless @config['plugin']['mount_config'].nil?
          @container_hash['HostConfig'] = { 'Binds' => ["#{Dir.pwd}/config/plugins/#{@name}.yml:#{@config['plugin']['mount_config']}"] }
        end
        @container_hash['Cmd'] = exec_data
        @container = Docker::Container.create(@container_hash)
        @container.tap(&:start).attach(tty: true)
        response = @container.logs(stdout: true)
        @container.delete(force: true)
      when 'active'
        @container.exec([exec_data])
      end
    when 'api'
      # payload = {
      #   chat:
      #     {
      #       user: data_from_chat['user'],
      #       channel: data_from_chat['channel'],
      #       type: data_from_chat['type'],
      #       timestamp: data_from_chat['ts']
      #     },
      #   command: {
      #     # text without username or plugin name
      #     data: chat_text_array.drop(2)
      #   }
      # }
      # response = HTTParty.get(@config['plugin']['api']['url'], body: payload, headers: @headers)
      # else ?
      # Error log and chat?
      # Since it will only make it to this level if the bot was invoked
      # then may it is appropriate to state that the bot does not understand?
    end
    response
  end

  # Clears out existing container with the name planned to use
  # Avoids this error:
  # Uncaught exception: Conflict. The name "/hello_world" is already in use by container 23ee03db81c93cb7dd9eba206c3a7e.
  #      You have to remove (or rename) that container to be able to reuse that name.
  def clear_existing_container(name)
    begin
      container = Docker::Container.get(name)
    rescue StandardError => _error
      # puts "The #{name} container doesn't exist"
      # puts "#{error.class} was thrown with message #{error.message}"
      # puts error.inspect
      return false
    end
    container&.delete(force: true) if container
  end

  # Shutdown procedures for container and script plugins
  def shutdown(name)
    clear_existing_container(name)
  end

  # TODO: likely move to a helper class
  def lang_settings
    lang = {}
    case @config['plugin']['language']
    when 'ruby', 'rb'
      lang[:file_type] = '.rb'
      lang[:image] = 'slapi/ruby:latest'
    when 'python', 'py'
      lang[:file_type] = '.py'
      lang[:image] = 'slapi/python:latest'
    when 'node', 'nodejs', 'javascript', 'js'
      lang[:file_type] = '.js'
      lang[:image] = 'slapi/nodejs:latest'
    when 'bash', 'shell'
      lang[:file_type] = '.sh'
      lang[:image] = 'slapi/base:latest'
    # Future Languages for Script Type
    # Uncomment when ready for script languages
    # when 'php'
    #   lang[:file_type] = '.php' # or is this phar?
    #   lang[:image] = 'slapi/base:latest'
    # when 'posh', 'powershell'
    #   lang[:file_type] = '.ps'
    #   lang[:image] = 'slapi/base:latest'
    else
      # TODO: error logging for this
      # could also use the langage sent in
      lang[:file_type] = '.sh'
      lang[:image] = 'slapi/base:latest'
    end
    lang
  end
end
