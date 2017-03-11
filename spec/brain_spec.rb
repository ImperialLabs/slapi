# frozen_string_literal: true
require_relative '../lib/brain/redis.rb'
require 'spec_helper'

RSpec.describe Brain, '#exec' do

  before(:all) do
    @brain = Brain.new(MockSettings.new)
  end

  describe 'runs brain tests' do
    it 'saves successfully' do
      @brain.save('integration', 'test', 'data')
    end

    it 'queries key successfully' do
      expect(@brain.query_key('integration', 'test')).to eq(['data'])
    end

    it 'queries hash successfully' do
      expect(@brain.query_hash('integration')).to eq(['test'])
    end

    it 'deletes successfully' do
      @brain.delete('integration', 'test')
    end
  end
end
