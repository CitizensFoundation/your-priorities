def compile_asset?(path)
  # ignores any filename that begins with '_' (e.g. sass partials)
  # all other css/js/sass/image files are processed
  if File.basename(path) =~ /^[^_].*\.\w+$/
    puts "Compiling: #{path}"
    true
  else
    puts "Ignoring: #{path}"
    false
  end
end

PAPERCLIP_STORAGE_MECHANISM = :s3

YourPriorities::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  #config.action_controller.asset_host = ENV['CF_ASSET_HOST']

#  config.action_controller.asset_host = Proc.new do |source, request|
#    method = request.ssl? ? "https" : "http"
#    "#{method}://#{ENV['FOG_DIRECTORY']}.s3-website-us-east-1.amazonaws.com"
#  end

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :info

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
  config.assets.precompile += [ method(:compile_asset?).to_proc ]
  config.assets.precompile += %w( modernizr.js respond.js respond-proxy.html respond.proxy.js )

  # IE8 Hack to allow respond to work
  config.action_controller.asset_host = Proc.new { |source, request = nil, *_|
    if request and source =~ /respond\.proxy-.+(js|gif)$/
      "#{request.protocol}#{request.host_with_port}"
    else
      ENV['CF_ASSET_HOST']
    end
  }

  config.cache_store = :dalli_store
end
