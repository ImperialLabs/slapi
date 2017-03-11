# frozen_string_literal: true

# Docker Helpers for Plugin Class
# Its main functions are to:
#  1. Set Items to be binded/mounted to Plugin Container
#     - Include script if script type
#     - Include plugin config if configured with path to mount/bind
#  2. Set Script Language based on plugin config
#     - Language determines which image is pulled for script exec
class Plugin
  def bind_set(filename = nil, script = nil)
    @binds = []
    @logger.debug("Plugin: #{@name}: Setting Binds")
    @binds.push("#{Dir.pwd}/scripts/#{filename}:/scripts/#{filename}") if script
    @binds.push("#{Dir.pwd}/config/plugins/#{@name}.yml:#{@config['plugin']['mount_config']}") if @config['plugin']['mount_config']
  end

  def lang_settings(lang = nil)
    case lang
    when 'ruby', 'rb'
      { file_type: '.rb', image: 'slapi/ruby:latest' }
    when 'python', 'py'
      { file_type: '.py', image: 'slapi/python:latest' }
    when 'node', 'nodejs', 'javascript', 'js'
      { file_type: '.js', image: 'slapi/nodejs:latest' }
    when 'bash', 'shell', 'sh'
      { file_type: '.sh', image: 'slapi/base:latest' }
    else
      @logger.warn("Plugin: #{@name}: Language not set in config, defaulting to shell/bash")
      { file_type: '.sh', image: 'slapi/base:latest' }
    end
  end
end
