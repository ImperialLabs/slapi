require_relative '../lib/core/plugins.rb'
require 'spec_helper'

RSpec.describe Plugins, "#exec" do

    context "calls exec on pagerduty plugin" do
      it "lists successfully" do
        settings = MockSettings.new({})
        plugins = Plugins.new(settings)
        test_data = MockData.new({text: "<@ABC123> pager list"})
        
        expect(plugins.exec("pager", test_data)).to eq("Commands:\r
  pager list help [COMMAND]  # Describe subcommands or one specific subcommand\r
  pager list incident        # list specific incident\r
  pager list incident!       # list all incidents regardless of status\r
  pager list incidents       # list all incidents\r
  pager list on_calls        # list on calls\r
  pager list schedule        # list a specific schedule\r
  pager list schedules       # list schedules\r\n\r\n")
      end
    end

    context "calls plugin help - level 1" do
      it "returns help list successfully" do
        settings = MockSettings.new({})
        plugins = Plugins.new(settings)
        test_data = MockData.new({text: "<@ABC123> help pager"})
        
        expect(plugins.help(test_data)).to eq("pager:
    ack : acknowledge incident
    create : create items
    delete : delete items
    help : Describe available commands or one specific command
    list : list items
    resolve : resolve incident
    trigger : trigger incident
    update : update items
    version : Get the version of the Pager Tool\n")
      end
    end

    context "calls help level 1" do
      it "returns help list successfully" do
        settings = MockSettings.new({})
        plugins = Plugins.new(settings)
        test_data = MockData.new({})
        
        expect(plugins.help(test_data)).to eq("hello\npager\n")
      end
    end

    context "calls help level 2" do
      it "returns help list successfully" do
        settings = MockSettings.new({:help => {'level' => 2}})
        plugins = Plugins.new(settings)
        test_data = MockData.new({})
        
        expect(plugins.help(test_data)).to eq("hello:
    hello world : Says things
pager:
    ack : acknowledge incident
    create : create items
    delete : delete items
    help : Describe available commands or one specific command
    list : list items
    resolve : resolve incident
    trigger : trigger incident
    update : update items
    version : Get the version of the Pager Tool\n")
      end
    end
end
