require_relative '../lib/core/realtime.rb'
require 'spec_helper'

RSpec.describe RealTimeClient, "#exec" do

  context "bot name" do
    it "configures and returns successfully" do
      settings = MockSettings.new({:adapter => {'token' => 'abc123'}})
      real_time = RealTimeClient.new(settings)
      expect(real_time.bot_name).to eq("headroom")
    end
  end

  context "update plugin cache" do
    it "configures and returns successfully" do
      settings = MockSettings.new({:adapter => {'token' => 'abc123'}})
      real_time = RealTimeClient.new(settings)
      expect(real_time.update_plugin_cache).to be_a_kind_of(Array)
    end
  end

  # TODO: invalid_auth
  # NEED to work out valid auth or mocking service
  #context "run bot" do
  #  it "configures and returns successfully" do
  #    settings = MockSettings.new({:adapter => {'token' => 'abc123'}})
  #    real_time = RealTimeClient.new(settings)
  #    expect(real_time.run_bot).to be_a_kind_of(Array)
  #  end
  #end

end
