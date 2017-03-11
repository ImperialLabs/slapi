# frozen_string_literal: true
require 'capybara/rspec'

require_relative '../lib/slapi.rb'
Capybara.app = Slapi

describe 'call the speak API', type: :feature do
  it 'returns' do
    page.driver.post '/v1/speak', channel: '#integration_tests', text: '*Hello* `World` ~everbodeeeee~'
    expect(page).to have_content 'it worked'
  end
end

describe 'call the emote API', type: :feature do
  it 'returns' do
    page.driver.post '/v1/emote', channel: 'C445NT42J', text: 'dances a jig'
    expect(page).to have_content 'it worked'
  end
end

describe 'call the reload API', type: :feature do
  it 'returns' do
    page.driver.post '/reload'
    expect(page).to have_content 'it worked'
  end
end

describe 'call the attach API', type: :feature do
  it 'returns' do
    page.driver.post '/v1/attachment',
                     channel: '#integration_tests',
                     attachments:
                       {
                         fallback: 'Attachment Test',
                         pretext: 'I haz Attachment!',
                         title: 'everbodeeeee gets an Attachment!',
                         text: 'All attachments today only tree fitty!',
                         color: '#229954'
                       }
    expect(page).to have_content 'it worked'
  end
end

describe 'calls save to brain', type: :feature do
  it 'returns' do
    page.driver.post '/v1/save', plugin: 'integration', key: 'test', value: 'data'
    expect(page).to have_content 'it worked'
  end
end

describe 'calls query key from brain', type: :feature do
  it 'returns' do
    page.driver.header 'plugin', 'integration'
    page.driver.header 'key', 'test'
    page.driver.get '/v1/query_key'
    expect(page).to have_content 'data'
  end
end

describe 'calls query hash from brain', type: :feature do
  it 'returns' do
    page.driver.header 'plugin', 'integration'
    page.driver.get '/v1/query_hash'
    expect(page).to have_content 'test'
  end
end

describe 'calls delete from brain', type: :feature do
  it 'returns' do
    page.driver.post '/v1/delete', plugin: 'integration', key: 'test'
    expect(page).to have_content 'it worked'
  end
end
