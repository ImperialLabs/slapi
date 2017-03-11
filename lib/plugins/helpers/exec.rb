# frozen_string_literal: true

# Exec Helpers for Plugin Class
# Its main functions are to:
#  1. Sterlize data from chat
#  2. Set data passed to plugin based on data type set
class Plugin
  def sterilize(data)
    clean_text = data.text.sterilize
    data.text = clean_text
    data
  end

  def data_type(data_from_chat, chat_text_array)
    data_convert = data_from_chat.to_h
    @config['plugin']['data_type'] == 'all' ? data_convert.to_json : chat_text_array.drop(2)
  end
end
