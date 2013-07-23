require 'uri'
require 'contacts/version'

module Contacts

  Identifier = 'Ruby Contacts v' + VERSION::STRING

  def self.configure(configuration)
    configuration.each do |key, value|
      klass =
        case key.to_s
        when 'google'
          Google
        when 'yahoo'
          Yahoo
        when 'windows_live'
          WindowsLive
        else
          raise ArgumentError, "unknown consumer: #{key}"
        end
      klass.configure(value)
    end
  end

  class Contact
    attr_reader :name, :username, :emails

    def initialize(emails, name, username = "")
      @name = name
      @emails = Array(emails)
      @username = username
    end

    def email
      @emails.first
    end
  end

  def self.deserialize_consumer(name, serialized_data)
    klass = consumer_class_for(name) and
      klass.deserialize(serialized_data)
  end

  def self.new(name, *args, &block)
    klass = consumer_class_for(name) and
      klass.new(*args, &block)
  end

  def self.consumer_class_for(name)
    class_name = name.to_s.gsub(/(?:\A|_)(.)/){|s| $1.upcase}
    class_name.sub!(/Oauth/, 'OAuth')
    class_name.sub!(/Bbauth/, 'BBAuth')
    begin
      klass = const_get(class_name)
    rescue NameError
      return nil
    end
    klass < Consumer ? klass : nil
  end

  def self.verbose?
    'irb' == $0
  end
  
  class Error < StandardError
  end
  
  class TooManyRedirects < Error
    attr_reader :response, :location
    
    MAX_REDIRECTS = 2
    
    def initialize(response)
      @response = response
      @location = @response['Location']
      super "exceeded maximum of #{MAX_REDIRECTS} redirects (Location: #{location})"
    end
  end

  autoload :Util, 'contacts/util'
  autoload :Consumer, 'contacts/consumer'
  autoload :OAuthConsumer, 'contacts/oauth_consumer'
  autoload :Google, 'contacts/google'
  autoload :Yahoo, 'contacts/yahoo'
  autoload :WindowsLive, 'contacts/windows_live'
end
