# frozen_string_literal: true

# Client Helpers for Bot Class
# Its main functions are to:
#  1. Route Messages to Client
#     - Standard Text Chat
#     - Attachment Chat
#     - Emote Chat
#  2. Set response channel based on where request type
#     - Help request response in DM if set in Bot Config
#     - No channel set for API requests (debug level only message)
#     - Set to same channel as request
#  3. Set Chat listener pre-fix base on channel
#     - Listen for @bot, bot, or bot id as initiator if normal channel
#     - Above plus any line that starts with a listener if direct message
class Bot
  def chat(text, channel = nil, data = nil)
    @client.web_client.chat_postMessage(
      channel: channel ? channel : channel_set(data),
      as_user: true,
      text: text
    )
  end

  def chat_attachment(attachment, channel = nil, data = nil)
    @client.web_client.chat_postMessage(
      channel: channel ? channel : channel_set(data),
      as_user: true,
      attachments: [attachment]
    )
  end

  def chat_me(text, channel = nil, data = nil)
    @client.web_client.chat_meMessage(
      channel: channel ? channel : channel_set(data),
      text: text
    )
  end

  def channel_set(data)
    # Set channel to post based on dm_user option
    if data.empty?
      @logger.debug("Channel request wasn't given any data")
      nil
    elsif data.text.include? 'help'
      dm_info = @client.web_client.im_open user: data.user if @help_options['dm_user']
      @help_options['dm_user'] ? dm_info['channel']['id'] : data.channel
    else
      data.channel
    end
  end

  def bot_prefix(data)
    # Clean up listners and don't require @bot if in a DM
    # Spaces are included here and not in case statement for DM help (i.e.; "help" vs "@bot help")
    dm_listen = "(^#{@bot_name} |^@#{@bot_name} |^\<@#{@client.self.id}\> |^)"
    channel_listen = "(^#{@bot_name} |^@#{@bot_name} |^\<@#{@client.self.id}\> )"
    data.channel[0] == 'D' ? dm_listen : channel_listen
  end
end
