# frozen_string_literal: true

FactoryGirl.define do
  factory :chat_data do
    type 'message'
    channel 'ABC123'
    text '<@U4DEAQX1T> help'
    user 'ABC123'
    ts '1486678775.000385'
    team 'ABC123'
  end
end