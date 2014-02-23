require 'load_twitter_followers'

class TwitterController < ApplicationController
  
  def oauth_callback_url
    "https://#{Instance.current.base_url_w_sub_instance}/twitter/callback"
  end

  def prepare_access_token(oauth_token, oauth_token_secret,oauth_verifier)
    consumer = OAuth::Consumer.new(Instance.first.twitter_key, Instance.first.twitter_secret_key,
      { :site => "https://api.twitter.com",
        :scheme => :header
      })
    # now create the access token object from passed values
    token_hash = { :oauth_token => oauth_token,
                   :oauth_token_secret => oauth_token_secret,
                   :oauth_verifier => oauth_verifier
                 }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
    return access_token
  end

  def self.consumer
    OAuth::Consumer.new(Instance.first.twitter_key,Instance.first.twitter_secret_key,{ :site=>"http://api.twitter.com" })
  end

  def create
    @request_token = TwitterController.consumer.get_request_token(:oauth_callback => oauth_callback_url)
    session[:request_token] = @request_token.token
    session[:request_token_secret] = @request_token.secret
    # Send to twitter.com to authorize
    redirect_to @request_token.authorize_url+"&oauth_callback_url="+oauth_callback_url
    return
  end

  def callback
    # Exchange the request token for an access token.
    stored_request_token = session[:request_token]
    stored_request_token_secret = session[:request_token_secret]
    Rails.logger.debug("stored req tok: #{stored_request_token} secret #{stored_request_token_secret}")
    request_token = OAuth::RequestToken.new(TwitterController.consumer, session[:request_token], session[:request_token_secret])
    @access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    Rails.logger.debug(@access_token.inspect)
    @response = @access_token.get('/account/verify_credentials.json')
    Rails.logger.debug("Twitter Response: #{@response.inspect}")
    if @response.class == Net::HTTPOK
      Rails.logger.debug("Twitter Body: #{@response.body.inspect}")
      user_info = JSON.parse(@response.body)
      if not user_info['screen_name']
        flash[:error] = tr("Sign in from Twitter failed.", "controller/twitter")
        redirect_to Instance.current.homepage_url + "twitter/failed"
        return
      else
        if user_signed_in? # they are already logged in, need to sync this account to twitter
          u = User.find(current_user.id)
          u.update_with_twitter(user_info, @access_token.token, @access_token.secret, request)
         # Delayed::Job.enqueue LoadTwitterFollowers.new(u.id), 1
          redirect_to Instance.current.homepage_url + "twitter/connected"
          return          
        else # they aren't logged in, so we'll log them in to twitter
          u = User.find_by_twitter_id(user_info['id'].to_i)
          u = User.find_by_twitter_login(user_info['screen_name']) if not u
          if u # let's add the tokens to the account
            u.update_with_twitter(user_info, @access_token.token, @access_token.secret, request)
          end          
          # if we haven't found their account, let's create it...
          if not u
            u = User.create_from_twitter(user_info, @access_token.token, @access_token.secret, request) 
            #Delayed::Job.enqueue LoadTwitterFollowers.new(u.id), 1
          end
          if u # now it's time to update memcached (or their cookie if in single govt mode) that we've got their acct
            sign_in = u
            check_geoblocking
            if @geoblocked
              redirect_to Instance.current.homepage_url + "twitter/geoblocked"
            else
              redirect_to Instance.current.homepage_url + "twitter/success"
            end
          else
            redirect_to Instance.current.homepage_url + "twitter/failed"
          end
          return
        end
      end
    else
      Rails.logger.error "Failed to get twitter user info via OAuth"
      # The user might have rejected this application. Or there was some other error during the request.
      redirect_to Instance.current.homepage_url + "twitter/failed"
      return
    end
  end

  def geoblocked
    flash[:notice] = tr("This part of the website is not avilable for login in your country.", "controller/twitter")
    redirect_to redirect_back_path
  end
  
  def success
    flash[:notice] = tr("Welcome back, {user_name}.", "controller/twitter", :instance_name => Instance.current.name, :user_name => current_user.name)
    redirect_to redirect_back_path
  end
  
  def connected
    flash[:notice] = tr("Your Twitter account is now linked", "controller/twitter")
    redirect_to redirect_back_path
  end
  
  def failed
    flash[:error] = tr("Sign in from Twitter failed.", "controller/twitter")
    redirect_to redirect_back_path
  end

end
