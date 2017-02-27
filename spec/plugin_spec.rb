require_relative '../lib/core/plugin.rb'
require 'spec_helper'

RSpec.describe Plugin, "#exec" do

    context "calls exec on script plugin" do
      it "lists successfully" do
        hello_file = File.expand_path('fixtures/plugins/hello.yml', File.dirname(__FILE__))
        plugin = Plugin.new(hello_file)
        test_data = MockData.new({text: "<@ABC123> hello test"})
        
        
        expect(plugin.exec(test_data)).to eq("Hello World!\r\n")
      end
    end


    context "calls exec on docker plugin" do
      it "lists successfully" do
        pager_file = File.expand_path('fixtures/plugins/pager.yml', File.dirname(__FILE__))
        plugin = Plugin.new(pager_file)
        test_data = MockData.new({text: "<@ABC123> pager list"})
        
        
        expect(plugin.exec(test_data)).to eq("Commands:\r
  pager list help [COMMAND]  # Describe subcommands or one specific subcommand\r
  pager list incident        # list specific incident\r
  pager list incident!       # list all incidents regardless of status\r
  pager list incidents       # list all incidents\r
  pager list on_calls        # list on calls\r
  pager list schedule        # list a specific schedule\r
  pager list schedules       # list schedules\r\n\r\n")
      end
    end



end



