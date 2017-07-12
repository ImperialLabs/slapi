# frozen_string_literal: true

require 'capybara/rspec'

require_relative '../lib/slapi.rb'
Capybara.app = Slapi

describe 'POST #API', type: :feature, slack: true do
  it 'speaks' do
    page.driver.post '/v1/speak', channel: '#integration_tests', text: '*Hello* `World` ~everbodeeeee~'
    expect(page.status_code).to eq(200)
  end
  it 'emotes' do
    page.driver.post '/v1/emote', channel: 'C445NT42J', text: 'dances a jig'
    expect(page.status_code).to eq(200)
  end
  it 'returns' do
    page.driver.post '/reload'
    expect(page.status_code).to eq(200)
  end
end
