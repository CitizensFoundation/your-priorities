module Contacts
  module Util
    #
    # Freeze the given hash, and any hash values recursively.
    #
    def self.frozen_hash(hash={})
      hash.freeze
      hash.keys.each{|k| k.freeze}
      hash.values.each{|v| v.freeze}
      hash
    end

    #
    # Return a copy of +hash+ with the keys turned into Symbols.
    #
    def self.symbolize_keys(hash)
      result = {}
      hash.each do |key, value|
        result[key.to_sym] = value
      end
      result
    end
  end
end
