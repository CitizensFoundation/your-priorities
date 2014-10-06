=begin
Monologue.sidebar              = ["latest_posts", "latest_tweets"]   # this will add the latests posts and latests tweets in the right sidebar.
Monologue.show_rss_icon        = true # will show the RSS icon (with link) in the header)
Monologue.facebook_url         = "https://www.facebook.com/jipiboilycom" # if set, this will enable Facebook icon and link it to your Facebook page.
Monologue.google_plus_account_url = "https://plus.google.com/115273180419164295760/posts" # if set, this will enable Google+ icon and link it to that URL.
Monologue.linkedin_url         = "http://www.linkedin.com/in/jipiboily" # if set, will enable Linked In icon and link to this URL.
Monologue.github_username      = "http://github.com/jipiboily"  # if set, will enable Github icon and link to this URL.
Monologue.gauge_analytics_site_id = "your-gaug.es-id-here" # add your [Gaug.es](http://get.gaug.es/) id here to enable it.
Monologue.facebook_logo           = 'logo.png'  # used in the open graph protocol to display an image when a post is liked

Monologue::User.class_eval do
  self.table_name = 'users'

  def name
    self.login
  end

  def has_picture?
    false
  end

  def confirmed?
    true
  end

  def received_notifications

    []
  end

  def password_digest(p=nil)
    self.encrypted_password
  end
end
=end