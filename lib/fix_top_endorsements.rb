class FixTopEndorsements
  
  #TODO: Really have to figure out this bug so this doesn't have to run all the time.
  
  def perform
    puts "FixTopEndorsements.perform starting... at #{start_time=Time.now}"
    Instance.current = Instance.all.last
    for u in User.find_by_sql("select * from users where top_endorsement_id not in (select id from endorsements)")
      u.top_endorsement = u.endorsements.active.by_position.find(:all, :limit => 1)[0]
      u.save(:validate => false)        
      puts u.login
    end
    puts "FixTopEndorsements.perform stopping... at #{Time.now} total of #{Time.now-start_time}"
  end

end