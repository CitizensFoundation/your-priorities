# coding: utf-8

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
