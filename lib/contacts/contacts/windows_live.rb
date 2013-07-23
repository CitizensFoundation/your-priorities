require 'contacts'
require 'nokogiri'

module Contacts
  class WindowsLive < Consumer
    configuration_attribute :application_id
    configuration_attribute :secret_key
    configuration_attribute :privacy_policy_url
    configuration_attribute :return_url

    #
    # If this is set, then #authentication_url will force the given
    # +target+ URL to have this origin (= scheme + host + port). This
    # should match the domain that your Windows Live project is
    # configured to live on.
    #
    # Instead of calling #authorize(params) when the user returns, you
    # will need to call #forced_redirect_url(params) to redirect the
    # user to the true contacts handler. #forced_redirect_url will
    # handle construction of the query string based on the incoming
    # parameters.
    #
    # The intended use is for development mode on localhost, which
    # Windows Live forbids redirection to. Instead, you may register
    # your app to live on "http://myapp.local", set :force_origin =>
    # 'http://myapp.local:3000', and map the domain to 127.0.0.1 via
    # your local hosts file. Your handlers will then look something
    # like:
    #
    #     def handler
    #       if ENV['HTTP_METHOD'] == 'POST'
    #         consumer = Contacts::WindowsLive.new
    #         redirect_to consumer.authentication_url(session)
    #       else
    #         consumer = Contacts::WindowsLive.deserialize(session[:consumer])
    #         consumer.authorize(params)
    #         contacts = consumer.contacts
    #       end
    #     end
    #
    # Since only the origin is forced -- not the path part of the URL
    # -- the handler typically redirects to itself. The second time
    # through it is a GET request.
    #
    # Default: nil
    #
    # Example: http://myapp.local
    #
    configuration_attribute :force_origin

    attr_accessor :token_expires_at, :delegation_token
    
    def initialize(options={})
      @token_expires_at = nil
      @location_id = nil
      @delegation_token = nil
    end

    def initialize_serialized(data)
      @token_expires_at = Time.at(data['token_expires_at'].to_i)
      @location_id = data['location_id']
      @delegation_token = data['delegation_token']
    end

    def serializable_data
      data = {}
      data['token_expires_at'] = @token_expires_at.to_i if @token_expires_at
      data['location_id'] = @location_id if @location_id
      data['delegation_token'] = @delegation_token if @delegation_token
      data
    end

    def authentication_url(target=self.return_url, options={})
      if force_origin
        context = target
        target = force_origin + URI.parse(target).path
      end

      url = "https://consent.live.com/Delegation.aspx"
      query = {
        'ps' => 'Contacts.Invite',
        'ru' => target,
        'pl' => privacy_policy_url,
        'app' => app_verifier,
      }
      query['appctx'] = context if context
      "#{url}?#{params_to_query(query)}"
    end

    def forced_redirect_url(params)
      target_origin = params['appctx'] and
        "#{target_origin}?#{params_to_query(params)}"
    end

    def authorize(params)
      consent_token_data = params['ConsentToken'] or
        raise Error, "no ConsentToken from Windows Live"
      eact = backwards_query_to_params(consent_token_data)['eact'] or
        raise Error, "missing eact from Windows Live"
      query = decode_eact(eact)
      consent_authentic?(query) or
        raise Error, "inauthentic Windows Live consent"
      params = query_to_params(query)
      @token_expires_at = Time.at(params['exp'].to_i)
      @location_id = params['lid']
      @delegation_token = params['delt']
      true
    rescue Error => error
      @error = error.message
      false
    end

    def contacts(options={})
      return nil if @delegation_token.nil? || @token_expires_at < Time.now
      # TODO: Handle expired token.
      xml = request_contacts
      parse_xml(xml)
    end

    private

    def signature_key
      OpenSSL::Digest::SHA256.digest("SIGNATURE#{secret_key}")[0...16]
    end

    def encryption_key
      OpenSSL::Digest::SHA256.digest("ENCRYPTION#{secret_key}")[0...16]
    end

    def app_verifier
      token = params_to_query({
        'appid' => application_id,
        'ts' => Time.now.to_i,
      })
      token << "&sig=#{CGI.escape(Base64.encode64(sign(token)))}"
    end

    def sign(token)
      OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, signature_key, token)
    end

    def decode_eact(eact)
      token = Base64.decode64(CGI.unescape(eact))
      iv, crypted = token[0...16], token[16..-1]
      cipher = OpenSSL::Cipher::AES128.new("CBC")
      cipher.decrypt
      cipher.iv = iv
      cipher.key = encryption_key
      cipher.update(crypted) + cipher.final
    end

    def consent_authentic?(query)
      body, encoded_signature = query.split(/&sig=/)
      signature = Base64.decode64(CGI.unescape(encoded_signature))
      sign(body) == signature
    end

    #
    # Like #query_to_params, but do the unescaping *before* the
    # splitting on '&' and '=', like Microsoft does it.
    #
    def backwards_query_to_params(data)
      params={}
      CGI.unescape(data).split(/&/).each do |pair|
        key, value = *pair.split(/=/)
        params[key] = value ? value : ''
      end
      params
    end

    def request_contacts
      http = Net::HTTP.new('livecontacts.services.live.com', 443)
      http.use_ssl = true
      url = "/users/@L@#{@location_id}/rest/invitationsbyemail"
      authorization = "DelegatedToken dt=\"#{@delegation_token}\""
      http.get(url, {"Authorization" => authorization}).body
    end

    def parse_xml(xml)
      document = Nokogiri::XML(xml)
      document.search('/LiveContacts/Contacts/Contact').map do |contact|
        email = contact.at('PreferredEmail').inner_text.strip
        names = []
        element = contact.at('Profiles/Personal/FirstName') and
          names << element.inner_text.strip
        element = contact.at('Profiles/Personal/LastName') and
          names << element.inner_text.strip
        Contact.new(email,names.join(' '))
      end
    end
  end
end
