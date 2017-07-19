# frozen_string_literal: true

# Client Helpers for Slapi Class
# Its main functions are to:
#  1. Route Messages to Client
#     - Standard Text Chat
#     - Attachment Chat
#     - Emote Chat
class Slapi
  def self.chat(text, channel = nil, data = nil)
    @bot.chat(text, channel, data)
  end

  def self.chat_attachment(attachment, channel = nil, data = nil)
    @bot.chat_attachment(attachment, channel, data)
  end

  def self.chat_me(text, channel = nil, data = nil)
    @bot.chat_me(text, channel, data)
  end
end
