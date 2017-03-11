# frozen_string_literal: true

# Slapi Brain Helper for Sinatra Extension Access
class Slapi
  def self.query_key(hash_name, key)
    @logger.debug("Key retrieved for #{hash_name}")
    @brain.query_key(hash_name, key)
  end

  def self.query_hash(hash_name)
    @logger.debug("Hash retrieved for #{hash_name}")
    @brain.query_hash(hash_name)
  end

  def self.delete(hash_name, key)
    @logger.debug("Data deleted for #{hash_name}")
    @brain.delete(hash_name, key)
  end

  def self.save(hash_name, key, value)
    @logger.debug("Data saved for #{hash_name}")
    @brain.save(hash_name, key, value)
  end
end
