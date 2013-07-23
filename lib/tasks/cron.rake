task :cron => :environment do

  Instance.current = Instance.all.last

  # crawls through everyone's account and makes sure their endorsement positions are accurate
  for u in User.active.at_least_one_endorsement.all(:order => "users.id asc")
    row = 0
    changed = false
    for e in u.endorsements.active.by_position
      row += 1
      if e.position != row
        e.update_attribute(:position,row) 
        changed = true
      end
      if u.top_endorsement_id != e.id and row == 1
        changed = true
        u.update_attribute(:top_endorsement_id,e.id) 
      end
    end
    if changed
      # updates their counts
      u.update_counts
      u.save(:validate => false)
      puts "updated endorsement positions of " + u.login
    end
  end

  # update the user counts for all users who logged in during the last 25 hours, just to make sure they're right
  for u in User.find(:all, :conditions => "last_sign_in_at > '#{Time.now-25.hours}'")
    u.update_counts
    u.save(:validate => false)
    puts "updated counts of " + u.login
  end

  # thin out the rankings and user rankings table, deleting everything older than 8 days
  Ranking.connection.execute("delete from rankings where created_at < '#{Time.now-8.days}'")
  UserRanking.connection.execute("delete from user_rankings where created_at < '#{Time.now-8.days}'")
  if Instance.current.is_branches?
    BranchEndorsementRanking.connection.execute("delete from branch_endorsement_rankings where created_at < '#{Time.now-8.days}'")
    BranchUserRanking.connection.execute("delete from branch_user_rankings where created_at < '#{Time.now-8.days}'")
  end
  puts "thinned out old rankings"

  # follow all the new followers for twitter users
  users = User.authorized_twitterers.active.by_twitter_crawled_at
  for user in users
    Delayed::Job.enqueue LoadTwitterFollowers.new(user.id), -2
  end

  if Time.now.wday == 0 # if it's saturday
    
    # deduct capital for people who haven't logged in recently
    users = User.active.no_recent_login.find(:all, :conditions => "capitals_count > 3")
    for user in users
      capital_lost = -((((Time.now-user.loggedin_at)/86400)/30).round/2)
      capital_to_deduct = capital_lost.round - user.inactivity_capital_lost
      if capital_to_deduct < 0
        ActivityCapitalInactive.create(:user => user, :capital => CapitalInactive.create(:recipient => user, :amount => capital_to_deduct))
        puts "deducted " + capital_to_deduct.to_s + "pc from " + user.login + " for not logging in recently"
      end
    end
    
    # update related ideas
    
    ideas = Idea.published.tagged.top_rank.all
    for idea in ideas
      time_started = Time.now
      keep = []
      next unless idea.has_tags?
      if idea.up_endorsements_count > 2
        rel_query = Idea.find_by_sql(["
        SELECT ideas.id, count(endorsements.id) as number, count(endorsements.id)/? as percentage, count(endorsements.id)/up_endorsements_count as endorsement_score
        FROM endorsements,ideas
        where endorsements.idea_id = ideas.id
        and endorsements.idea_id <> ?
        and endorsements.status = 'active'
        and endorsements.value = 1
        and ideas.id in (#{idea.all_idea_ids_in_same_tags.join(',')})
        and endorsements.user_id in (#{idea.up_endorser_ids.join(',')})
        and ideas.status = 'published'
        group by ideas.id
        having count(endorsements.id)/? > 0.2
        order by endorsement_score desc
        limit 5",idea.up_endorsements_count,idea.id,idea.up_endorsements_count])
        for p in rel_query
          pct = (p.percentage.to_f*100).to_i
          next unless pct > 19
          rel = RelationshipEndorserEndorsed.find_by_idea_id_and_other_idea_id(idea.id,p.id)
          if rel
            rel.update_attribute("percentage",pct) unless rel.percentage == pct
          else
            rel = RelationshipEndorserEndorsed.create(:idea => idea, :other_idea => Idea.find(p.id), :percentage => pct)
          end
          keep << rel.id
        end
      end
      
      if idea.endorsements_count > 2
        rel_query = Idea.find_by_sql(["
        SELECT ideas.*, count(endorsements.id) as number, count(endorsements.id)/? as percentage, count(endorsements.id)/endorsements_count as endorsement_score
        FROM endorsements,ideas
        where endorsements.idea_id = ideas.id
        and endorsements.idea_id <> ?
        and endorsements.status = 'active'
        and ideas.id in (#{idea.all_idea_ids_in_same_tags.join(',')})
        and endorsements.user_id not in (#{idea.endorser_ids.join(',')})
        and ideas.status = 'published'
        group by ideas.id
        having count(endorsements.id)/? > 0.2        
        order by endorsement_score desc
        limit 5",idea.undecideds.size, idea.id, idea.undecideds.size])
        for p in rel_query
          pct = (p.percentage.to_f*100).to_i
          next unless pct > 19        
          rel = RelationshipUndecidedEndorsed.find_by_idea_id_and_other_idea_id(idea.id,p.id)
          if rel
            rel.update_attribute("percentage",pct) unless rel.percentage == pct
          else
            rel = RelationshipUndecidedEndorsed.create(:idea => idea, :other_idea => Idea.find(p.id), :percentage => pct)
          end
          keep << rel.id
        end
      end
      
      if idea.down_endorsements_count > 2
        rel_query = Idea.find_by_sql(["
        SELECT ideas.*, count(endorsements.id) as number, count(endorsements.id)/? as percentage, count(endorsements.id)/down_endorsements_count as endorsement_score
        FROM endorsements,ideas
        where endorsements.idea_id = ideas.id
        and endorsements.idea_id <> ?
        and endorsements.status = 'active'
        and endorsements.value = 1
        and ideas.id in (#{idea.all_idea_ids_in_same_tags.join(',')})
        and endorsements.user_id in (#{idea.down_endorser_ids.join(',')})
        and ideas.status = 'published'
        group by ideas.id
        having count(endorsements.id)/? > 0.2    
        order by endorsement_score desc
        limit 5",idea.down_endorsements_count,idea.id,idea.down_endorsements_count])
      
        for p in rel_query
          pct = (p.percentage.to_f*100).to_i
          next unless pct > 19        
          rel = RelationshipOpposerEndorsed.find_by_idea_id_and_other_idea_id(idea.id,p.id)
          if rel
            rel.update_attribute("percentage",pct) unless rel.percentage == pct
          else
            rel = RelationshipOpposerEndorsed.create(:idea => idea, :other_idea => Idea.find(p.id), :percentage => pct)
          end
          keep << rel.id
        end
      end
      
      old_rels = Relationship.who_endorsed.find(:all, :conditions => ["id not in (?) and idea_id = ?",keep,idea.id])
      for rel in old_rels
        rel.destroy
      end
      puts 'updated related ideas ' + idea.name + ' ' + (Time.now-time_started).seconds.to_s
    end
    
  end

end