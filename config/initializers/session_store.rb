# Be sure to restart your server when you modify this file.
begin
  if Rails.env.development? 
    YourPriorities::Application.config.session_store :cookie_store, key: "_Instance.first.domain_name.gsubstaging_dev"
  elsif Rails.env.test?
      YourPriorities::Application.config.session_store :cookie_store, key: "_Instance.first.domain_name.test_dev"
  elsif ENV['YRPRI_ALL_DOMAIN']
    YourPriorities::Application.config.session_store :cookie_store, key: "_#{Instance.first.domain_name.gsub(".","_")}_production_all_domain", :domain => ".#{Instance.first.domain_name}"
  else
    YourPriorities::Application.config.session_store :cookie_store, key: "_#{Instance.first.domain_name.gsub(".","_")}_production"
  end
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# YourPriorities::Application.config.session_store :active_record_store
