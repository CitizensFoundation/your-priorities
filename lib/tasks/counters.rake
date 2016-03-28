namespace :counters do
  # Count ideas per month
  # Idea.unscoped.group("DATE_TRUNC('month', created_at)").count.each do |x,y| puts "#{x.to_s.gsub(" 00:00:00","")},#{y}\n" end

  desc "Export ones with most invites"
  task :export_user_with_most_notifications => :environment do
    users = {}
    User.unscoped.all.each do |user|
      if user.notifications.count>0
        users[user.email] = 0 unless users[user.email]!=nil
        users[user.email] += user.notifications.count
      end
    end
    puts
    puts "With regular notification"
    puts users.count
    puts
    users.sort_by { |a,b| b }.each do |email,value|
      #puts "#{email},#{value}"
    end
    puts
    IdeaStatusChangeLog.all.each do |change|
      Endorsement.unscoped.where(:idea_id => change.idea_id).all.each do |endorsement|
        users[endorsement.user.email] = 0 unless users[endorsement.user.email]
        users[endorsement.user.email] += 1
      end
    end
    puts
    puts "With status included"
    puts users.count
    puts
    at_least_10 = []
    users.sort_by { |a,b| b }.each do |email,value|
      #puts "#{email},#{value}"
      if value>9
        at_least_10 << email
      end
    end
    puts
    puts "All with notifications"
    puts
    users.sort_by { |a,b| b }.each do |email,value|
      #puts "#{email}"
    end
    puts
    puts "At least 10"
    puts at_least_10.length
    at_least_10.each do |email|
      #puts email
    end
    puts
    puts "Less than 10"
    puts User.unscoped.count-at_least_10.length
    User.unscoped.all.each do |user|
      puts user.email unless at_least_10.include?(user.email)
      users[user.email] = 0 unless users[user.email]
      users[user.email] += 1
    end


    IdeaStatusChangeLog.all.each do |change|
      Endorsement.unscoped.find(change.idea_id).all.each do |endorsement|
        users[endorsement.email] = 0 unless users[endorsement.email]
        users[user.email] += 1
      end
    end
    puts users.count
    puts
    users.each do |email,value|
      puts email + ": " + value
    end
  end

  desc "Count all"
  task :count_all => :environment do
    Idea.unscoped.all.each do | idea |
      puts "Processing #{idea.name}"
      Idea.unscoped do
        Point.unscoped do
          Activity.unscoped do
            idea.reload(:lock=>true)
            idea.counter_endorsements_up = idea.up_endorsers.count
            idea.counter_endorsements_down = idea.down_endorsers.count
            idea.counter_points = idea.points.count
            #idea.counter_comments = idea.comments.count
            idea.counter_all_activities = idea.activities.count
            idea.save(:validate=>false)
          end
        end
      end
    end

    SubInstance.all.each do | sub_instance |
      puts "Processing #{sub_instance.short_name}"
      sub_instance.reload(:lock=>true)
      sub_instance.counter_ideas = sub_instance.ideas.count
      sub_instance.counter_points = sub_instance.points.count
      sub_instance.counter_users = sub_instance.users.count
      sub_instance.counter_comments = sub_instance.comments.count
      sub_instance.save(:validate=>false)
    end


  end

end
