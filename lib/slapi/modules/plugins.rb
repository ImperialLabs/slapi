# frozen_string_literal: true

# Plugin Helpers for Slapi Class
# Its main functions are to:
#  1. Allow Reloading of Plugins
class Slapi
  # Allows reloads from
  def self.reload_plugins
    @bot.reload_plugins
  end
end
