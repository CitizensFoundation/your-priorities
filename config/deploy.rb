set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"")
require "rvm/capistrano"
require 'bundler/capistrano'
require 'airbrake/capistrano'
require "thinking_sphinx/capistrano"
require "auto_html/capistrano"
#set :whenever_command, "bundle exec whenever"
#require "whenever/capistrano"

set :rvm_type, :user
ssh_options[:forward_agent] = true
set :application, "social_innovation_internal"
set :domain, "idea-synergy.com"
set :scm, "git"
set :repository, "git@github.com:rbjarnason/social_innovation_internal.git"
set :selected_branch, "artemis"
set :branch, "#{selected_branch}"
set :use_sudo, false
set :deploy_to, "/home/si/sites/#{application}/#{selected_branch}"
set :user, "si"
set :deploy_via, :remote_cache
set :shared_children, shared_children + %w[assets db/hourly_backup db/daily_backup db/weekly_backup]

role :app, "x", :primary => true
role :web, "x"

##role :db,  "sql", :primary => true

namespace :deploy do
  task :start do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

before 'deploy:update_code' do
end

after 'deploy:update_code' do
#  thinking_sphinx.stop
#  thinking_sphinx.configure
#  thinking_sphinx.rebuild
end

after 'deploy:finalize_update' do
  run "mkdir -p #{deploy_to}/#{shared_dir}/sphinx"
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/* #{current_release}/config/"
  run "mkdir #{current_release}/lib/geoip"
  run "ln -nfs #{deploy_to}/#{shared_dir}/geoip/GeoIP.dat #{current_release}/lib/geoip/GeoIP.dat"
  run "ln -nfs #{deploy_to}/#{shared_dir}/assets #{current_release}/public/assets"
  run "ln -nfs #{deploy_to}/#{shared_dir}/system #{current_release}/public/system" 
end

namespace :delayed_job do
  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec ruby script/delayed_job restart"
  end
end

after "deploy", "delayed_job:restart"

        require './config/boot'
        require 'airbrake/capistrano'
