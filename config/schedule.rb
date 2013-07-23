# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, "/home/yrpri/sites/social_innovation_internal/yrpri2/shared/log/cron_log.log"

every 5.minutes do
  rake "schedule:fix_top_endorsements"
end

every 15.minutes do
  rake "ts:index"
end

every :reboot do
  rake "ts:index"
  rake "ts:start"
  command "cd /home/yrpri/sites/social_innovation_internal/yrpri2/current; RAILS_ENV=production ruby script/delayed_job start"
end

every 50.minutes do
  rake "schedule:idea_ranker"
end

every 55.minutes do
  rake "schedule:user_ranker"
end

every 6.hours do
  rake "schedule:fix_counts"
end

every 1.hour do
  command "cd /home/yrpri/sites/social_innovation_internal/yrpri2/current; bundle exec backup perform -t hourly_backup --config_file config/backup.rb --data-path db --log-path log --tmp-path tmp"
end

every 1.day do
  command "cd /home/yrpri/sites/social_innovation_internal/yrpri2/current; bundle exec backup perform -t daily_backup --config_file config/backup.rb --data-path db --log-path log --tmp-path tmp"
end

every 1.week do
  command "cd /home/yrpri/sites/social_innovation_internal/yrpri2/current; bundle exec backup perform -t weekly_backup --config_file config/backup.rb --data-path db --log-path log --tmp-path tmp"
end

every 1.month do
  command "cd /home/yrpri/sites/social_innovation_internal/yrpri2/current; bundle exec backup perform -t monthly_backup --config_file config/backup.rb --data-path db --log-path log --tmp-path tmp"
end
