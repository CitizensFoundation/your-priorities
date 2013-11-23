Monologue.config do |config|
  config.site_name = "Betri Reykjavík"
  config.site_subtitle = "Umræður um Betri Reykjavík"
  config.site_url = "https://www.betrireykjavik.is/"

  config.meta_description = "Betri Reykjavík er..."
  config.meta_keyword = "betri reykjavik,better reykjavik,edemocracy,democracy,city"

  config.admin_force_ssl = false
  config.posts_per_page = 10

  config.disqus_shortname = "hmm"

  # LOCALE
  config.twitter_locale = "en" # "fr"
  config.facebook_like_locale = "en_US" # "fr_CA"
  config.google_plusone_locale = "en"

  config.layout               = "layouts/application"

  # ANALYTICS
  # config.gauge_analytics_site_id = "YOUR COGE FROM GAUG.ES"
  # config.google_analytics_id = "YOUR GA CODE"

  config.sidebar = ["latest_posts", "latest_tweets", "categories", "tag_cloud"]


  #SOCIAL
  config.twitter_username = "y"
  config.facebook_url = "https://www.facebook.com/betrireykjavik"
  config.facebook_logo = 'logo.png'
  config.google_plus_account_url = "https://plus.google.com/u/1/11527364295760/posts"
  config.linkedin_url = "http://www.linkedin.com/in/joily"
  config.github_username = "jioily"
  config.show_rss_icon = true

end
