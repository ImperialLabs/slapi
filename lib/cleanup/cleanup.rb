# frozen_string_literal: true

require 'yaml'
require 'docker'
require 'logger'
require 'active_support/core_ext/object/blank'
require_relative 'helpers/language'

# Cleanup class will cleanup and leftover scripts, plugins after shutdown
# Its two main functions are to:
#  1. Load plugin names to check against docker and clear out any containers still running
#  2. Remove any scripts still on hosts (configurable)
class Cleanup
  def initialize
    ['bot.test.yml', 'bot.local.yml', 'bot.test.yml'].each do |file|
      if File.file?(File.expand_path('../../config/' + file, File.dirname(__FILE__)))
        @config = YAML.load_file(File.expand_path('../../config/' + file, File.dirname(__FILE__)))
        break
      end
    end
    @managed = @type == 'api' ? false : true
    log_level = ENV['RACK_ENV'] == 'production' ? 'info' : 'error'
    @logger = Logger.new(STDOUT)
    @logger.level = log_level
  end

  def shutdown
    clean_plugins
    clean_brain
  end

  def clean_brain
    @logger.debug('Cleanup: Removing Brain Container')
    clean_container('slapi_brain')
  end

  def clean_plugins
    file_location = @config['plugins']['location'] ? @config['plugins']['location'] : '../../config/plugins/*.yml'

    yaml_files = File.expand_path(file_location + '*.yml', File.dirname(__FILE__))
    Dir.glob(yaml_files).each do |file|
      @logger.debug('Cleanup: ' + File.basename(file, '.*') + ': cleaning containers and scripts')
      @plugin_config = YAML.load_file(file)
      @managed = @config['plugin']['managed'] if @config.dig('plugin', 'managed')
      clean_container(File.basename(file, '.*')) if @managed
      clean_script(File.basename(file, '.*'), file) if @plugin_config['plugin']['type'] == 'script'
    end
  end

  def clean_script(name, file)
    file = File.expand_path('../../scripts/' + name + lang(@plugin_config['plugin']['language']), File.dirname(__FILE__))
    @logger.debug("Cleanup: Deleting script #{file}")
    File.delete(file) if File.exist?(file)
  end

  def clean_container(name)
    container = Docker::Container.get(name)
    container&.delete(force: true) if container
  rescue StandardError => _error
    false
  end
end
