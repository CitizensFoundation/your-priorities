require 'contacts'
require 'json'

module Contacts
  class Yahoo < OAuthConsumer
    CONSUMER_OPTIONS = Util.frozen_hash(
      :site => "https://api.login.yahoo.com",
      :request_token_path => "/oauth/v2/get_request_token",
      :access_token_path => "/oauth/v2/get_token",
      :authorize_path => "/oauth/v2/request_auth"
    )

    REQUEST_TOKEN_PARAMS = {}

    def initialize(options={})
      super(CONSUMER_OPTIONS, REQUEST_TOKEN_PARAMS)
    end

    def initialize_serialized(data)
      super
      if @access_token && (guid = data['guid'])
        @access_token.params['xoauth_yahoo_guid'] = guid
      end
    end

    def contacts(options={})
      return nil if @access_token.nil?
      params = {:limit => 200}.update(options)
      yahoo_params = translate_contacts_options(params).merge('format' => 'json')
      guid = @access_token.params['xoauth_yahoo_guid']
      uri = URI.parse("http://social.yahooapis.com/v1/user/#{guid}/contacts")
      uri.query = params_to_query(yahoo_params)
      begin
        response = @access_token.get(uri.to_s)
      rescue OAuth::Unauthorized => error
        # Token probably expired.
        @error = error.message
        return nil
      end
      parse_contacts(response.body)
    end

    def serializable_data
      data = super
      data['guid'] = @access_token.params['xoauth_yahoo_guid'] if @access_token
      data
    end

    private

    def translate_contacts_options(options)
      params = {}
      value = options[:limit] and
        params['count'] = value
      value = options[:offset] and
        params['start'] = value
      params['sort'] = (value = options[:descending]) ? 'desc' : 'asc'
      params['sort-fields'] = 'email'
      # :updated_after not supported. Yahoo! appears to support
      # filtering by updated, but does not support a date comparison
      # operation. Lame. TODO: filter unwanted records out of the
      # response ourselves.
      params
    end

    def parse_contacts(text)
      result = JSON.parse(text)
      if result['contacts']
      result['contacts']['contact'].map do |contact_object|
        name, emails = nil, []
        contact_object['fields'].each do |field_object|
          case field_object['type']
          when 'nickname'
            name = field_object['value']
          when 'name'
            name ||= field_object['value'].values_at('givenName', 'familyName').compact.join(' ')
          when 'email'
            emails << field_object['value']
          end
        end
        next if emails.empty?
        Contact.new(emails, name)
      end.compact
      else
        []
      end
    end
  end
end
