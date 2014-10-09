# coding: utf-8

require 'csv'

def create_tags(row)
  tags = []
  tags << row[1]
  tags << row[2]
  tags << row[3]
  tags << row[4]
  tags << row[5]
  tags << row[6]
  tags.join(",")
end

def create_idea_from_row(row,current_user,sub_instance)
  idea_name = row[0].mb_chars.slice(0..59)
  idea_tags = create_tags(row)
  point_name = row[7].mb_chars.slice(0..59)
  point_text = row[8].mb_chars.slice(0..499)
  point_link = row[9]
  
  begin
    Idea.transaction do
      @idea = Idea.new
      @idea.name = idea_name
      @idea.user = current_user
      @idea.ip_address = "127.0.0.1"
      @idea.issue_list = idea_tags
      @idea.sub_instance_id = sub_instance.id
      puts @idea.inspect
      @saved = @idea.save
      puts @saved

      if @saved
        @point = Point.new
        @point.user = current_user
        @point.idea_id = @idea.id
        @point.content = point_text
        @point.name = point_name
        @point.value = 1
        @point.website = point_link if point_link and point_link != ""
        @point.sub_instance_id = sub_instance.id
        puts @point.inspect
        @point_saved = @point.save
      end
      puts @point_saved
      if @point_saved
        if Revision.create_from_point(@point.id)
          @quality = @point.point_qualities.find_or_create_by_user_id_and_value(current_user.id,true)
        end      
      end
      raise "rollback" if not @point_saved or not @saved
    end
  rescue => e
    puts "ROLLBACK ERROR ON IMPORT"
    puts e.message
  end    
end

CODE_TO_SHORTNAME = {"AE"=>"uae", "LY"=>"lybia", "VA"=>"vatican",
                     "PS"=>"ps", "GB"=>"uk", "SY"=>"syria", "RU"=>"russia",
                     "MD"=>"moldova", "LA"=>"lao" }
namespace :utils do
  desc "Export sub instance to csv"
  task :export_sub_instance_to_csv => :environment do
    ["barcombe-hamsey","chailey-wivelsfield","ditchling-westmeston","kingston",
     "lewes","newhaven","newick","ousevalley-ringmer","peacehaven","plumpton",
     "saltdean-telscombe-cliffs","seaford"].each do |short_name|
      sub_instance = SubInstance.where(:short_name=>short_name).first
      puts "Space,"+short_name
      puts ""
      puts "User email,Idea name,Idea description,Up votes,Down votes,Point name,Point description,Point value"
      Idea.unscoped.where(:sub_instance_id=>sub_instance.id).each do |idea|
        puts "#{idea.user.email},\"#{idea.name}\",\"#{idea.description.gsub("\"","''")}\",#{idea.up_endorsers.count},#{idea.down_endorsers.count}"
        Point.unscoped.where(:idea_id=>idea.id).each do |point|
          puts ",,,,,\"#{point.name}\",\"#{point.content.gsub("\"","''").gsub("\n"," ")}\",#{point.value>0 ? 'Support' : 'Opposes'}"
        end
      end
    end
  end

  desc "Sub instance stats"
  task :sub_instance_stats => :environment do
    #from = SubInstance.where(:short_name=>ENV['SHORT_NAME']).first
    puts "Space,Users,Ideas,Points,Comments"
    ["barcombe-hamsey","chailey-wivelsfield","ditchling-westmeston","kingston",
     "lewes","newhaven","newick","ousevalley-ringmer","peacehaven","plumpton",
     "saltdean-telscombe-cliffs","seaford"].each do |short_name|
      SubInstance.where(:short_name=>short_name).each do |from|
        puts "#{from.short_name},#{User.unscoped.where(:sub_instance_id=>from.id).count},#{Idea.unscoped.where(:sub_instance_id=>from.id).count},"+
              "#{Point.unscoped.where(:sub_instance_id=>from.id).count},#{Comment.unscoped.where(:sub_instance_id=>from.id).count}"
      end
    end

  end

  desc "Export users from sub instances"
  task :export_users_from_sub_instances => :environment do
    #from = SubInstance.where(:short_name=>ENV['SHORT_NAME']).first
    puts "Space,Name,Email,Sign in count"
    ["barcombe-hamsey","chailey-wivelsfield","ditchling-westmeston","kingston",
    "lewes","newhaven","newick","ousevalley-ringmer","peacehaven","plumpton",
    "saltdean-telscombe-cliffs","seaford"].each do |short_name|
      SubInstance.where(:short_name=>short_name).each do |from|
        User.unscoped.where(:sub_instance_id=>from.id).each do |user|
          puts "#{from.short_name},#{user.login},#{user.email},#{user.sign_in_count}"
        end
      end
    end
  end


  desc "Destroy sub_instances from csv url"
  task :destroy_sub_instances_from_csv_url => :environment do
    from = SubInstance.where(:short_name=>ENV['SHORT_NAME_TO_CLONE']).first # barcombe-hamsey
    csv = CSV.parse(open(ENV['CSV_URL_TO_CLONE_FROM'])) # https://s3.amazonaws.com/yrpri-direct-asset/lewes.csv
    a_user = nil
    csv.each_with_index do |site,i|
      puts site
      next if site[1]==ENV['SHORT_NAME_TO_CLONE']
      s = SubInstance.where(:short_name=>site[1]).first
      s.short_name = "#{rand(432432434)}"
      s.save
    end
  end

  desc "Clone from sub instance"
  task :clone_from_sub_instance_to_csv_url => :environment do
    from = SubInstance.where(:short_name=>ENV['SHORT_NAME_TO_CLONE']).first # barcombe-hamsey
    csv = CSV.parse(open(ENV['CSV_URL_TO_CLONE_FROM'])) # https://s3.amazonaws.com/yrpri-direct-asset/lewes.csv
    csv.each_with_index do |site,i|
      next if site.empty?
      a_user = nil
      a_how_to_user_category = nil
      puts site
      next if site[1]==ENV['SHORT_NAME_TO_CLONE']
      new_sub_instance = from.dup
      new_sub_instance.name = site[0]
      new_sub_instance.short_name = site[1]
      new_sub_instance.logo = from.logo
      new_sub_instance.ask_for_post_code = true
      new_sub_instance.top_banner = from.top_banner
      new_sub_instance.save
      SubInstance.current = new_sub_instance
      User.unscoped.where(:sub_instance_id=>from.id).each do |item|
        new_item = item.dup
        new_item.invitation_token = nil
        new_item.sub_instance_id = new_sub_instance.id
        new_item.save(:validate=>false)
        a_user = new_item if a_user == nil
      end
      Category.unscoped.where(:sub_instance_id=>from.id).each do |item|
        new_item = item.dup
        new_item.sub_instance_id = new_sub_instance.id
        new_item.icon = item.icon
        new_item.save(:validate=>false)
        a_how_to_user_category = new_item if new_item.name=="How to use"
      end
      Page.unscoped.where(:sub_instance_id=>from.id).each do |item|
        new_item = item.dup
        new_item.sub_instance_id = new_sub_instance.id
        new_item.content = new_item.content.gsub("http://zeroheroesbarcombehamsey.eventbrite.co.uk/",site[2])
        puts new_item.content
        new_item.content = new_item.content.gsub("Barcombe and Hamsey",new_sub_instance.name)
        new_item.content = new_item.content.gsub("Barcombe Village Hall",site[3])
        new_item.content = new_item.content.gsub("3rd of June",site[4])
        puts new_item.content
        new_item.save(:validate=>false)
      end
      Idea.unscoped.where(:sub_instance_id=>from.id).each do |item|
        new_item = item.dup
        new_item.sub_instance_id = new_sub_instance.id
        new_item.user = a_user
        new_item.category = a_how_to_user_category
        new_item.save(:validate=>false)
        Point.unscoped.where(:idea_id=>item.id, :sub_instance_id=>from.id).each do |point|
          new_point = point.dup
          new_point.sub_instance_id = new_sub_instance.id
          new_point.idea_id = new_item.id
          new_point.user = a_user
          new_point.save(:validate=>false)
          Revision.unscoped.where(:point_id=>point.id).each do |revision|
            new_revision = revision.dup
            new_revision.point_id = new_point.id
            new_revision.user = a_user
            new_revision.save(:validate=>false)
            new_revision.recreate_author_sentences(new_point)
          end
        end
      end
      Endorsement.unscoped.where(:sub_instance_id=>from.id).each do |item|
        new_item = item.dup
        new_item.sub_instance_id = new_sub_instance.id
        new_item.user = a_user
        new_item.save(:validate=>false)
      end
      Activity.unscoped.where(:sub_instance_id=>from.id).each do |item|
        new_item = item.dup
        new_item.sub_instance_id = new_sub_instance.id
        new_item.user = a_user
        new_item.save(:validate=>false)
      end
    end
  end

  desc "fix_endorsement_positions_for_better_iceland"
  task :fix_endorsement_positions_for_better_iceland => :environment do
    #Endorsement.all.each do |e| puts e.position end
    #Endorsement.where("sub_instance_id IS NULL").all.each do |e| puts Idea.unscoped.find(e.idea_id).name end;get chomp
    #Endorsement.where("sub_instance_id IS NULL").all.each do |e| puts e.created_at end;get chomp
    Endorsement.where("sub_instance_id IS NULL").all.each do |e| e.sub_instance_id=SubInstance.where(:short_name=>"default").first.id;e.save end
    User.unscoped.all.each do |user|
      SubInstance.current = SubInstance.find(user.sub_instance_id)
      Endorsement.where(:user_id=>user.id,:sub_instance_id=>user.sub_instance_id).all.each do |e|
        puts SubInstance.current = SubInstance.find(user.sub_instance_id)
        e.insert_at(1)
        e.save
      end
    end
  end

  desc "FixBetterNeighborhoodSubInstances"
  task :fix_bn do
    SubInstance.all.each do |sub_instance|
      if sub_instance.short_name.include?("betri-hverfi")
        sub_instance_2012 = sub_instance.dup
        sub_instance_2012.short_name = sub_instance_2012.short_name+"-2012"
        sub_instance_2012.name = sub_instance_2012.name+" 2012"
        sub_instance_2012.save

        sub_instance_2014 = sub_instance.dup
        sub_instance_2014.short_name = sub_instance_2014.short_name+"-2014"
        sub_instance_2014.name = sub_instance_2014.name+" 2014"
        sub_instance_2014.save

        sub_instance.short_name = sub_instance.short_name+"-2013"
        sub_instance.name = sub_instance.name+" 2013"
        sub_instance.save

        Idea.unscoped.where(:sub_instance_id=>sub_instance).each do |x|
          if x.created_at<DateTime.parse("01/01/2013")
            x.sub_instance_id = sub_instance_2012.id
            x.save(:validate=>false)
          end
        end

        Point.unscoped.where(:sub_instance_id=>sub_instance).each do |x|
          if x.created_at<DateTime.parse("01/01/2013")
            x.sub_instance_id = sub_instance_2012.id
            x.save(:validate=>false)
          end
        end

        Comment.unscoped.where(:sub_instance_id=>sub_instance).each do |x|
          if x.created_at<DateTime.parse("01/01/2013")
            x.sub_instance_id = sub_instance_2012.id
            x.save(:validate=>false)
          end
        end

        Endorsement.unscoped.where(:sub_instance_id=>sub_instance).each do |x|
          if x.created_at<DateTime.parse("01/01/2013")
            x.sub_instance_id = sub_instance_2012.id
            x.save(:validate=>false)
          end
        end

      end
    end
  end

  desc "Move ideas and points to a new user"
  task :move_ideas_to_new_user => :environment do
    raise 'Needs sub_instance_short_name= from_user= and to_user=' unless ENV['sub_instance_short_name'] and ENV['from_user'] and ENV['to_user']
    sub_instance = SubInstance.where(:short_name=>ENV['sub_instance_short_name']).first
    from_user = User.where(:email=>ENV['from_user'], :sub_instance_id=>sub_instance.id).first
    to_user = User.where(:email=>ENV['to_user'], :sub_instance_id=>sub_instance.id).first
    puts "Moving all ideas from #{from_user.login} to #{to_user.login} on #{sub_instance.short_name}"
    puts "Yes?"
    STDIN.gets.chomp
    puts Idea.unscoped.where(:sub_instance_id=>sub_instance.id, :user_id=>from_user.id).update_all(:user_id=>to_user.id)
    Point.unscoped.where(:sub_instance_id=>sub_instance.id, :user_id=>from_user.id).all.each do |p|
      puts p.name
      p.user_id = to_user.id
      p.revisions.each do |r|
        r.user_id = to_user.id
        r.recreate_author_sentences(p)
        r.save(:validate=>false)
      end
      puts p.save(:validate=>false)
    end
    puts Activity.unscoped.where(:sub_instance_id=>sub_instance.id, :user_id=>from_user.id).update_all(:user_id=>to_user.id)
    puts Endorsement.unscoped.where(:sub_instance_id=>sub_instance.id, :user_id=>from_user.id).update_all(:user_id=>to_user.id)
    puts "The end"
  end

  desc "Create BR categories"
  task :delete_all_from_process_documents => :environment do
    ProcessDocumentElement.delete_all
    ProcessDocument.delete_all
  end


  desc "Create BR categories"
  task :create_br_categories => :environment do
  end

  desc "Create sub_instances from iso countries"
  task :create_sub_instances_from_iso => :environment do
    IsoCountry.all.each do |country|
      p=SubInstance.new
      p.name = country.country_english_name
      p.geoblocking_enabled = true
      p.geoblocking_open_countries = country.code.downcase
      if CODE_TO_SHORTNAME[country.code]
        p.short_name = CODE_TO_SHORTNAME[country.code]
      else
        p.short_name = country.country_english_name.downcase.gsub(" ","-").gsub(",","").gsub("(","").gsub(")","").gsub("'","").gsub(",","").gsub(".","")
      end
      puts p.short_name
      p.iso_country_id = country.id
      p.save unless SubInstance.find_by_iso_country_id(country.id)
    end
  end

  desc "Dump users csv"
  task :dump_users_csv => :environment do
    all_users = User.unscoped.all
    puts "All users count #{all_users.count}"
    puts "Login,Email"
    all_users.each_with_index do |u,i|
      if u.email
        unless u.email.include?("@ibuar.is")
          puts "\"#{u.login}\",#{u.email}"
        end
      else
       # puts "no email for #{u.id} #{u.login}"
      end
    end
  end

  desc "Dump database to tmp"
  task :dump_db => :environment do
    config = Rails.application.config.database_configuration
    current_config = config[Rails.env]
    abort "db is not mysql" unless current_config['adapter'] =~ /mysql/
    
    database = current_config['database']
    user = current_config['username']
    password = current_config['password']
    host = current_config['host']
    
    path = Rails.root.join("tmp","sqldump")
    base_filename = "#{database}_#{Time.new.strftime("%d%m%y_%H%M%S")}.sql.gz"
    filename = path.join(base_filename)

    FileUtils.mkdir_p(path)
    command = "mysqldump --add-drop-table -u #{user} -h #{host} --password=#{password} #{database} | gzip > #{filename}"
    puts "Excuting #{command}"
    system command
    if ENV['scpit']
      command = "scp #{filename} yrpri@88.208.206.52:/home/yrpri/backups/#{base_filename}"
      puts "Excuting #{command}"
      system command
    end
  end

  desc "Archive processes"
  task(:archive_processes => :environment) do
      if ENV['current_thing_id']
        logg = "#{ENV['current_thing_id']}. log"
        puts "Archiving all processes except for thing: #{logg}"
        IdeaProcess.find(:all).each do |c|
          puts c.external_info_3
          unless c.external_info_3.index(logg)
            puts "ARCHIVING"
            c.archived = true
            c.save
          end
        end
      end
  end

  desc "Backup"
  task(:backup => :environment) do
      filename = "skuggathing_#{Time.new.strftime("%d%m%y_%H%M%S")}.sql"
      system("mysqldump -u robert --password=X --force odd_dev_2 > /home/robert/#{filename}")
      system("gzip /home/robert/#{filename}")
      system("scp /home/robert/#{filename}.gz robert@where.is:backups/#{filename}.gz")
      system("rm /home/robert/#{filename}.gz")
  end

  desc "Delete Fully Processed Masters"
  task(:delete_fullly_processed_masters => :environment) do
      masters = ProcessSpeechMasterVideo.find(:all)
      masters.each do |master_video|
        puts "master_video id: #{master_video.id} all_done: #{master_video.process_speech_videos.all_done?} has_any_in_processing: #{master_video.process_speech_videos.any_in_processing?}"
        if master_video.process_speech_videos.all_done? and not master_video.process_speech_videos.any_in_processing?
          master_video_flv_filename = "#{Rails.root.to_s}/private/"+ENV['Rails.env']+"/process_speech_master_videos/#{master_video.id}/master.flv"
          if File.exist?(master_video_flv_filename)
            rm_string = "rm #{master_video_flv_filename}"
            puts rm_string
            system(rm_string)
          end
        end
      end
  end

  desc "Delete Not Valid Video Folders"
  task(:delete_not_valid_video_folders => :environment) do
      Dir.entries("public/development/process_speech_videos").each do |filename|
        next if filename=="." or filename==".."
        unless ProcessSpeechVideo.exists?(filename.to_i)
          puts "rm -r public/development/process_speech_videos/#{filename}"
        else
          puts "Keeping public/development/process_speech_videos/#{filename}"
        end
      end
  end

  desc "Explore broken videos"
  task(:explore_broken_videos => :environment) do
      masters = ProcessSpeechMasterVideo.find(:all)
      masters.each do |master_video|
        unless master_video.process_speech_videos.all_done? and not master_video.process_speech_videos.any_in_processing?
          master_video_flv_filename = "#{Rails.root.to_s}/private/"+ENV['Rails.env']+"/process_speech_master_videos/#{master_video.id}/master.flv"
          if File.exist?(master_video_flv_filename)
            puts "master_video id: #{master_video.id} all_done: #{master_video.process_speech_videos.all_done?} has_any_in_processing: #{master_video.process_speech_videos.any_in_processing?}"
            master_video.process_speech_videos.each do |video|
              puts "video id #{video.id} published #{video.published} #{video.title} in_processing #{video.in_processing} duration: #{video.duration_s} in: #{video.inpoint_s}"            
            end
            puts " "
          end
        end
      end
  end

  desc "Expoirt idea categories"
  task(:export_idea_categories => :environment) do
    csv_data = CSV.generate do |csv|
      csv << Category.all.collect {|c| "#{c.name} - #{c.id}"}
      csv << []
      csv << ["Idea name","Category id"]
      Idea.all.each do |p|
        if p.category
          csv << ["\"#{p.name.gsub("\"","")}\"",p.category.id]
        else
          csv << ["\"#{p.name.gsub("\"","")}\"",0]
        end
      end
    end
    puts csv_data
  end

  desc "Import ideas"
  task(:import_ideas => :environment) do
    @current_instance = Instance.last
    if @current_instance
      @current_instance.update_counts
      Instance.current = @current_instance
    end
    unless current_user = User.find_by_email("island@skuggathing.is")
      current_user=User.new
      current_user.email = "island@skuggathing.is"
      current_user.login = "Island.is"
      current_user.save(:validate => false)
    end
    f = File.open(ENV['csv_import_file'])
    sub_instance = SubInstance.find_by_short_name(ENV['sub_instance_short_name'])
    CSV.parse(f.read) do |row|
      puts row.inspect
      create_idea_from_row(row, current_user, sub_instance)
    end
  end
end
