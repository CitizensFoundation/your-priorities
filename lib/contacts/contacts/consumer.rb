module Contacts
  class Consumer
    #
    # Configure this consumer from the given hash.
    #
    def self.configure(configuration)
      @configuration = Util.symbolize_keys(configuration)
    end

    #
    # The configuration for this consumer.
    #
    def self.configuration
      @configuration
    end

    #
    # Define an instance-level reader for the named configuration
    # attribute.
    #
    # Example:
    #
    #     class MyConsumer < Consumer
    #       configuration_attribute :app_id
    #     end
    #
    #     MyConsumer.configure(:app_id => 'foo')
    #     consumer = MyConsumer.new
    #     consumer.app_id    # "foo"
    #
    def self.configuration_attribute(name)
      class_eval <<-EOS
        def #{name}
          self.class.configuration[:#{name}]
        end
      EOS
    end

    def initialize(options={})
    end

    #
    # Return a string of serialized data.
    #
    # You may reconstruct the consumer by passing this string to
    # .deserialize.
    #
    def serialize
      params_to_query(serializable_data)
    end

    #
    # Create a consumer from the given +string+ of serialized data.
    #
    # The serialized data should have been returned by #serialize.
    #
    def self.deserialize(string)
      data = string ? query_to_params(string) : {}
      consumer = new
      consumer.initialize_serialized(data) if data
      consumer
    end

    #
    # Authorize the consumer's token from the given
    # parameters. +params+ is the request parameters the user is
    # redirected to your site with.
    #
    # Return true if authorization is successful, false otherwise. If
    # unsuccessful, an error message is set in #error. Authorization
    # may fail, for example, if the user denied access, or the
    # authorization is forged.
    #
    def authorize(params)
      raise NotImplementedError, 'abstract'
    end

    #
    # An error message for the last call to #authorize.
    #
    attr_accessor :error

    #
    # Return the list of contacts, or nil if none could be retrieved.
    #
    def contacts
      raise NotImplementedError, 'abstract'
    end

    protected

    def initialize_serialized(data)
      raise NotImplementedError, 'abstract'
    end

    def serialized_data
      raise NotImplementedError, 'abstract'
    end

    def self.params_to_query(params)
      params.map do |key, value|
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end.join('&')
    end

    def self.query_to_params(data)
      params={}
      data.split(/&/).each do |pair|
        key, value = *pair.split(/=/)
        params[CGI.unescape(key)] = value ? CGI.unescape(value) : ''
      end
      params
    end

    def params_to_query(params)
      self.class.params_to_query(params)
    end

    def query_to_params(data)
      self.class.query_to_params(data)
    end
  end
end
