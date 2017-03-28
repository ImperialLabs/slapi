# frozen_string_literal: true

# Docker Helpers for Plugin Class
# Its main functions are to:
#  1. Set Items to be binded/mounted to Plugin Container
#     - Include script if script type
#     - Include plugin config if configured with path to mount/bind
#  2. Set Script Language based on plugin config
#     - Language determines which image is pulled for script exec
class Cleanup
  def lang(lang = nil)
    case lang
    when 'ruby', 'rb'
      '.rb'
    when 'python', 'py'
      '.py'
    when 'node', 'nodejs', 'javascript', 'js'
      '.js'
    else
      '.sh'
    end
  end
end
