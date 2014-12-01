namespace :counters do
  
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