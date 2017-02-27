# frozen_string_literal: true
require 'capybara/rspec'
require_relative '../slapi.rb'
Capybara.app = Slapi

describe 'call the speak API', type: :feature do
  it 'returns' do
    page.driver.post '/v1/speak', channel: '#integration_tests', text: '*Hello* `World` ~everbodeeeee~'
    expect(page).to have_content 'it worked'
  end
end

describe 'call the help API', type: :feature do
  it 'returns' do
    page.driver.post '/v1/speak', channel: '#integration_tests', text: 'help'
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
    page.driver.post '/reload', channel: 'C445NT42J', text: 'reload'
    expect(page).to have_content 'it worked'
  end
end

describe 'call the attach API', type: :feature do
  it 'returns' do
    page.driver.post '/v1/attachment',
                     channel: '#integration_tests',
                     text: 'Hello World',
                     attachments:
                       {
                         fallback: "New ticket from Andrea Lee - Ticket #1943: Can't rest my password - https://groove.hq/path/to/ticket/1943",
                         pretext: 'New ticket from Andrea Lee',
                         title: "Ticket #1943: Can't reset my password",
                         title_link: 'https://groove.hq/path/to/ticket/1943',
                         text: 'Help! I tried to reset my password but nothing happened!',
                         color: '#7CD197'
                       }
    expect(page).to have_content 'it worked'
  end
end
