# frozen_string_literal: true
require_relative 'lib/cleanup/cleanup.rb'

at_exit do
  cleanup = Cleanup.new
  cleanup.shutdown
  puts 'Cleanup Complete, safe to exit'
  exit(0)
end

require './lib/slapi'
run Slapi
