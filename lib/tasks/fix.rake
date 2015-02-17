
class Helper
  include Singleton
  include ActionView::Helpers::SanitizeHelper
end

def self.help
  Helper.instance
end

def remove_all_endorsements_except
  # 15436
  # 2818
  # 18254

  ids = [14,10,3,60,99,14,108,56,22,10,28,25,55,121,99,7,68,113,135].uniq
  # Check if any endorsements in ids
  total = 0
  ids.each.each do |id|
    puts total+=Endorsement.find_all_by_idea_id(id).count
  end
  puts total
  Endorsement.delete_all(["endorsements.idea_id NOT IN (?)",ids])
  Endorsement.all.each_with_index do |e,i|
    puts i
    e.status = "finished"
    e.position = nil
    e.save
  end
end

def shall_we_change(col_name)
  new_col_name = col_name
  new_col_name = new_col_name.gsub("priorities","ideas") if new_col_name.index("priorities")
  new_col_name = new_col_name.gsub("priority","idea") if new_col_name.index("priority")
  new_col_name = new_col_name.gsub("governments","instances") if new_col_name.index("governments")
  new_col_name = new_col_name.gsub("partners","sub_instances") if new_col_name.index("partners")
  new_col_name = new_col_name.gsub("partner","sub_instance") if new_col_name.index("partner")
  new_col_name = new_col_name.gsub("deleted_at","removed_at") if new_col_name.index("deleted_at")
  new_col_name = new_col_name.gsub(/_change$/,"_delta") if new_col_name.index("_change")
  if new_col_name == col_name
    return nil
  else
    return new_col_name
  end
end

def change_to_mysql_text(text)
  if text=="integer"
    return "int(11)"
  elsif text=="text"
    return "text"
  elsif text=="datetime"
    return "datetime"
  elsif text=="float"
    return "float"
  elsif text=="boolean"
    return "tinyint(1)"
  else
    raise text
  end
end

namespace :fix do
  desc "Resend status msg"
  task :resend_status_msg do
    Thread.current[:skip_default_scope_globally] = true
    IdeaStatusChangeLog.where(["created_at <= ? AND created_at >= ?",DateTime.parse("17/02/2015 13:00"), DateTime.parse("28/01/2015 05:00")]).each do |change_log|
      next if change_log.id<2399
      puts change_log.id
      idea = Idea.find(change_log.idea_id)
      User.send_status_email(idea.id, idea.official_status, change_log.date, change_log.subject, change_log.content)
    end
    Thread.current[:skip_default_scope_globally] = nil
  end

  desc "FixCat"
  task :fix_cat do
    Category.unscoped.all.each do |c|
      if c.sub_instance_id == nil
        c.sub_instance_id = SubInstance.find_by_short_name("default").id
        c.save
      end
    end
  end

  desc "Clear sub instance graphics"
  task :clear_sub_instance_graphics => :environment do
    SubInstance.all.each do |s|
      s.top_banner.destroy
      s.external_link_logo.destroy
      s.logo.destroy
      s.menu_strip_side.destroy
      s.save
    end
  end


  desc "Set up locale weights"
  task :setup_locale_weights => :environment do
    {"en"=>1,"is"=>2,"fr"=>3,"bg"=>4,"it"=>5}.each do |k,w|
      locale = Tolk::Locale.find_by_name(k)
      locale.weight = w
      locale.save
    end
  end

  desc "Reset db db"
  task :reset_db_YES => :environment do
    connection = ActiveRecord::Base.connection();
    connection.execute("DELETE FROM activities;")
    connection.execute("DELETE FROM ads;")
    connection.execute("DELETE FROM capitals;")
   # connection.execute("DELETE FROM categories;")
    connection.execute("DELETE FROM comments;")
    connection.execute("DELETE FROM delayed_jobs;")
    connection.execute("DELETE FROM endorsements;")
    connection.execute("DELETE FROM feeds;")
    connection.execute("DELETE FROM following_discussions;")
    connection.execute("DELETE FROM followings;")
    connection.execute("DELETE FROM groups;")
    connection.execute("DELETE FROM groups_users;")
    connection.execute("DELETE FROM idea_charts;")
    connection.execute("DELETE FROM idea_revisions;")
    connection.execute("DELETE FROM idea_status_change_logs;")
    connection.execute("DELETE FROM ideas;")
    connection.execute("DELETE FROM impressions;")
    connection.execute("DELETE FROM notifications;")
    connection.execute("DELETE FROM pictures;")
    connection.execute("DELETE FROM point_qualities;")
    connection.execute("DELETE FROM points;")
    connection.execute("DELETE FROM profiles;")
    connection.execute("DELETE FROM rankings;")
    connection.execute("DELETE FROM relationships;")
    connection.execute("DELETE FROM revisions;")
    connection.execute("DELETE FROM shown_ads;")
    connection.execute("DELETE FROM signups;")
    connection.execute("DELETE FROM tag_subscriptions;")
    connection.execute("DELETE FROM taggings;")
    connection.execute("DELETE FROM tags;")
    connection.execute("DELETE FROM unsubscribes;")
    connection.execute("DELETE FROM users;")
    connection.execute("DELETE FROM user_charts;")
    connection.execute("DELETE FROM user_contacts;")
    connection.execute("DELETE FROM user_rankings;")
    connection.execute("DELETE FROM widgets;")
  end

  desc 'comment_category'
  task :comment_category => :environment do
    Comment.transaction do
      Comment.unscoped.where(category_name: "no cat").each do |comment|
        activity = Activity.unscoped.find(comment.activity_id)
        if activity.idea_id
          idea = Idea.unscoped.find(activity.idea_id)
          if idea.category_id
            category = Category.unscoped.find_by_id(idea.category_id)
            if category
              comment.category_name = category.name
              comment.save
            end
          end
        elsif activity.point_id
          point = Point.unscoped.find(activity.point_id)
          idea = Idea.unscoped.find(point.idea_id)
          if idea.category_id
            category = Category.unscoped.find_by_id(idea.category_id)
            if category
              comment.category_name = category.name
              comment.save
            end
          end
        end
      end
    end
  end

  desc 'duplicate_emails'
  task :duplicate_emails => :environment do
    User.transaction do
      User.find(:all, :group => [:email], :having => "count(*) > 1").each do |dupe|
        dupe_users = User.find(:all, :conditions => {:email => dupe.email}, :order => "last_sign_in_at ASC")
        if dupe.email
          good_user = dupe_users.pop
          puts "keeping user #{good_user.id}'s email of #{dupe.email}"
        end
        dupe_users.each do |dupe_user|
          random_string = (0...8).map{65.+(rand(25)).chr}.join
          if dupe.email
            new_email = "#{random_string}.#{dupe.email}"
          else
            new_email = "#{random_string}@example.com"
          end
          puts "changing user #{dupe_user.id}'s email of #{dupe.email} to #{new_email}"
          dupe_user.email = new_email
          dupe_user.save(validate: false)
        end
      end
    end
  end

  desc 'fixdesc'
  task :fixdesc => :environment do
    Idea.unscoped.all.each do |idea|
      if idea.points.where(sub_instance_id: idea.sub_instance_id).first
        puts idea.points.where(sub_instance_id: idea.sub_instance_id).first.content_html
        idea.description = idea.points.where(sub_instance_id: idea.sub_instance_id).first.content
        idea.save(:validate=>false)
      else
        puts "NO POINT FOR #{idea.id}"
      end
    end
  end

  desc 'rename_activities'
  task :rename_activities => :environment do
    renames = {
      'CapitalGovernmentNew' => 'CapitalInstanceNew',
      'IssuePriority1' => 'IssueIdea1',
      'PriorityDebut' => 'IdeaDebut',
      'IssuePriorityRising1' => 'IssueIdeaRising1',
    }
    renames.each do |old, new|
      puts "UPDATE activities SET type='Activity#{new}' where type='Activity#{old}';"
    end
  end

  desc 'show_broken_activities'
  task :show_broken_activities => :environment do
    Activity.unscoped.all.each do |activity|
      if activity.idea_id
        idea = Idea.unscoped.find(activity.idea_id)
        if activity.sub_instance_id != idea.sub_instance_id
          puts "activity #{activity.id} has sub_instance_id of #{activity.sub_instance_id} instead of #{idea.sub_instance_id} like its Idea"
        end
      elsif activity.point_id
        point = Point.unscoped.find(activity.point_id)
        if activity.sub_instance_id != point.sub_instance_id
          puts "activity #{activity.id} has sub_instance_id of #{activity.sub_instance_id} instead of #{point.sub_instance_id} like its Point"
        end
      elsif activity.ad_id
        ad = Ad.unscoped.find(activity.ad_id)
        if activity.sub_instance_id != ad.sub_instance_id
          puts "activity #{activity.id} has sub_instance_id of #{activity.sub_instance_id} instead of #{ad.sub_instance_id} like its Ad"
        end
      end
    end
  end

  desc 'fix_broken_activities'
  task :fix_broken_activities => :environment do
    Activity.unscoped.all.each do |activity|
      if activity.idea_id
        idea = Idea.unscoped.find(activity.idea_id)
        if activity.sub_instance_id != idea.sub_instance_id
          puts "activity #{activity.id} has sub_instance_id of #{activity.sub_instance_id} instead of #{idea.sub_instance_id} like its Idea"
          activity.sub_instance_id = idea.sub_instance_id
          activity.save
        end
      elsif activity.point_id
        point = Point.unscoped.find(activity.point_id)
        if activity.sub_instance_id != point.sub_instance_id
          puts "activity #{activity.id} has sub_instance_id of #{activity.sub_instance_id} instead of #{point.sub_instance_id} like its Point"
          activity.sub_instance_id = point.sub_instance_id
          activity.save
        end
      elsif activity.ad_id
        ad = Ad.unscoped.find(activity.ad_id)
        if activity.sub_instance_id != ad.sub_instance_id
          puts "activity #{activity.id} has sub_instance_id of #{activity.sub_instance_id} instead of #{ad.sub_instance_id} like its Ad"
          activity.sub_instance_id = ad.sub_instance_id
          activity.save
        end
      end
    end
  end

  desc 'show_broken_points'
  task :show_broken_points => :environment do
    Idea.unscoped.all.each do |idea|
      Point.unscoped.where(idea_id: idea.id).all.each do |point|
        if point.sub_instance_id != idea.sub_instance_id
          puts "point #{point.id} has sub_instance_id of #{point.sub_instance_id} instead of #{idea.sub_instance_id}"
        end
      end
    end
  end

  desc 'fix_broken_points'
  task :fix_broken_points => :environment do
    Idea.unscoped.all.each do |idea|
      Point.unscoped.where(idea_id: idea.id).all.each do |point|
        if point.sub_instance_id != idea.sub_instance_id
          puts "point #{point.id} has sub_instance_id of #{point.sub_instance_id} instead of #{idea.sub_instance_id}"
          point.sub_instance_id = idea.sub_instance.id
          point.save
        end
      end
    end
  end

  desc 'clear_tr8n'
  task :clear_tr8n => :environment do
    Tr8n::Translation.delete_all
  end

  desc 'it2'
  task :it2 => :environment do
    Tagging.update_all("taggable_type='Idea' where taggable_type='Idea'")
    Notification.update_all("notifiable_type='Idea' where notifiable_type='Idea'")
    ['General', 'Localization', 'User interface', 'Data sources'].each do |name|
      category = Category.find_by_name(name)
      category.destroy
    end
  end

  desc "it"
  task :it => :environment do
    #Drop and Create database
    #drop database yrpri_translate_temp;
    #CREATE database yrpri_translate_temp;
    #use yrpri_translate_temp;
    #mysql -u root -p yrpri_translate_temp < /home/robert/work/temp/s.sql
    #rake fix:it
    #copy paste
    #DELETE FROM on target
    # Create new default sub_instance
    #UPDATE activities SET sub_instance_id = 12 WHERE sub_instance_id IS NULL;
    #UPDATE ads set sub_instance_id = 12 where sub_instance_id IS NULL;
    #UPDATE comments set sub_instance_id = 12 where sub_instance_id IS NULL;
    #UPDATE groups set sub_instance_id = 12 where sub_instance_id IS NULL;
    #UPDATE ideas set sub_instance_id = 12 where sub_instance_id IS NULL;
    #UPDATE points set sub_instance_id = 12 where sub_instance_id IS NULL;
    #UPDATE rankings set sub_instance_id = 12 where sub_instance_id IS NULL;
    #UPDATE tags set sub_instance_id = 12 where sub_instance_id IS NULL;
    #rake fix:fix_broken_points
    #rake fix:fix_broken_activities
    #rake fix:duplicate_emails
    #rake db:migrate

    #mysqldump --skip-triggers --compact --complete-insert --no-create-info -u root -p yrpri_translate_temp > /home/robert/work/temp/yrpri_trans.sql
    #mysql -u root -p si_dev < /home/robert/work/temp/yrpri_trans.sql

    used_list = %w[activities ads capitals categories comments endorsements following_discussions followings governments notifications partners point_qualities pictures points
                 priorities priority_charts priority_status_change_logs profiles rankings relationships shown_ads revisions signups tag_subscriptions taggings tags
                 unsubscribes user_charts user_contacts user_rankings users]

    table_rename_list = [
      %w[partners sub_instances],
      %w[priorities ideas],
      %w[governments instances],
      %w[priority_charts idea_charts],
      %w[priority_status_change_logs idea_status_change_logs]
    ]

    action_rename = %w[ActivityPriorityNew ActivityPriorityFlagInappropriate ActivityPriorityFlag ActivityPriorityBury ActivityPriorityCommentNew ActivityPriority1
       ActivityPriorityDebut ActivityPriority1Opposed ActivityPriorityRising1 ActivityIssuePriority1 ActivityIssuePriorityControversial1 ActivityPriorityMergeProposal ActivityPriorityRenamed
       ActivityPriorityAcquisitionProposalNo ActivityPriorityAcquisitionProposalApproved ActivityPriorityAcquisitionProposalDeclined
       ActivityPriorityAcquisitionProposalDeleted ActivityPriorityOfficialStatusFailed ActivityPriorityOfficialStatusCompromised
       ActivityPriorityOfficialStatusInTheWorks ActivityPriorityOfficialStatusSuccessful ActivityPriorityStatusUpdate
       ActivityPointRevisionOtherPriority ActivityIssuePriorityRising1 ActivityCapitalGovernmentNew
    ]

    notification_rename = %w[NotificationPriorityFlagged NotificationPriorityFinished]

    def rename_to_idea(text)
      text.gsub("Priority","Idea").gsub("Government","Instance")
    end

    action_rename.each do |rename|
      puts "UPDATE activities SET type='#{rename_to_idea(rename)}' where type='#{rename}';"
    end

    notification_rename.each do |rename|
      puts "UPDATE notifications SET type='#{rename_to_idea(rename)}' where type='#{rename}';"
    end


    puts "["
    used_list.each do |table|
      puts "{:#{table}=>%w[]},"
    end
    puts "]"



    used_columns_per_table = [
        {:activities=> {
                                       :id => :integer,
                                  :user_id => :integer,
                               :partner_id => :integer,
                                     :type => :string,
                                   :status => :string,
                              :priority_id => :integer,
                               :created_at => :datetime,
                             :is_user_only => :boolean,
                           :comments_count => :integer,
                              :activity_id => :integer,
                                  :vote_id => :integer,
                                :change_id => :integer,
                            :other_user_id => :integer,
                                   :tag_id => :integer,
                                 :point_id => :integer,
                              :revision_id => :integer,
                               :capital_id => :integer,
                                    :ad_id => :integer,
                              :document_id => :integer,
                     :document_revision_id => :integer,
                                 :position => :integer,
                          :followers_count => :integer,
                               :changed_at => :datetime,
            :priority_status_change_log_id => :integer}},
        {:ads=> {
                         :id => :integer,
                :priority_id => :integer,
                    :user_id => :integer,
             :show_ads_count => :integer,
            :shown_ads_count => :integer,
                       :cost => :integer,
              :per_user_cost => :float,
                      :spent => :float,
                  :yes_count => :integer,
                   :no_count => :integer,
                 :skip_count => :integer,
                     :status => :string,
                    :content => :string,
                 :created_at => :datetime,
                 :updated_at => :datetime,
                :finished_at => :datetime,
                   :position => :integer,
                 :partner_id => :integer
        }},
        {:capitals=>{
                            :id => :integer,
                     :sender_id => :integer,
                  :recipient_id => :integer,
              :capitalizable_id => :integer,
            :capitalizable_type => :string,
                        :amount => :integer,
                          :type => :string,
                          :note => :string,
                    :created_at => :datetime,
                    :updated_at => :datetime,
                       :is_undo => :boolean
        }},
        {:categories=>{
                           :id => :integer,
                         :name => :string,
                   :created_at => :datetime,
                   :updated_at => :datetime,
                   :partner_id => :integer,
               :icon_file_name => :string,
            :icon_content_type => :string,
               :icon_file_size => :integer,
              :icon_updated_at => :datetime,
                  :description => :text,
                     :sub_tags => :string
        }},
        {:comments=>{
                       :id => :integer,
              :activity_id => :integer,
                  :user_id => :integer,
                   :status => :string,
                  :content => :text,
               :created_at => :datetime,
               :updated_at => :datetime,
              :is_endorser => :boolean,
               :ip_address => :string,
               :user_agent => :string,
                 :referrer => :string,
               :is_opposer => :boolean,
             :content_html => :text,
              :flags_count => :integer,
              :category_id => :integer,
            :category_name => :string,
               :partner_id => :integer
        }},
        {:endorsements=> {
                     :id => :integer,
                 :status => :string,
               :position => :integer,
             :partner_id => :integer,
            :priority_id => :integer,
                :user_id => :integer,
             :ip_address => :string,
             :created_at => :datetime,
             :updated_at => :datetime,
            :referral_id => :integer,
                  :value => :integer,
                  :score => :integer
        }},
        {:following_discussions=>{
                     :id => :integer,
                :user_id => :integer,
            :activity_id => :integer,
             :created_at => :datetime,
             :updated_at => :datetime
        }},
        {:followings=>{
                       :id => :integer,
                  :user_id => :integer,
            :other_user_id => :integer,
                    :value => :integer,
               :created_at => :datetime,
               :updated_at => :datetime
        }},
        {:governments=>{
                                        :id => :integer,
                                    :status => :string,
                                :short_name => :string,
                               :domain_name => :string,
                                    :layout => :string,
                                      :name => :string,
                                   :tagline => :string,
                                     :email => :string,
                                 :is_public => :boolean,
                                :created_at => :datetime,
                                :updated_at => :datetime,
                                   :db_name => :string,
                          :official_user_id => :integer,
                  :official_user_short_name => :string,
                                    :target => :string,
                                   :is_tags => :boolean,
                               :is_facebook => :boolean,
                            :is_legislators => :boolean,
                                :admin_name => :string,
                               :admin_email => :string,
                     :google_analytics_code => :string,
                            :quantcast_code => :string,
                                 :tags_name => :string,
                             :briefing_name => :string,
                             :currency_name => :string,
                       :currency_short_name => :string,
                                  :homepage => :string,
                          :priorities_count => :integer,
                              :points_count => :integer,
                           :documents_count => :integer,
                               :users_count => :integer,
                        :contributors_count => :integer,
                            :partners_count => :integer,
            :official_user_priorities_count => :integer,
                        :endorsements_count => :integer,
                                :picture_id => :integer,
                           :color_scheme_id => :integer,
                                   :mission => :string,
                                    :prompt => :string,
                             :buddy_icon_id => :integer,
                               :fav_icon_id => :integer,
              :is_suppress_empty_priorities => :boolean,
                                 :tags_page => :string,
                          :facebook_api_key => :string,
                       :facebook_secret_key => :string,
                             :windows_appid => :string,
                        :windows_secret_key => :string,
                               :yahoo_appid => :string,
                          :yahoo_secret_key => :string,
                                :is_twitter => :boolean,
                               :twitter_key => :string,
                        :twitter_secret_key => :string,
                             :language_code => :string,
                                  :password => :string,
                            :logo_file_name => :string,
                         :logo_content_type => :string,
                            :logo_file_size => :integer,
                           :logo_updated_at => :datetime,
                      :buddy_icon_file_name => :string,
                   :buddy_icon_content_type => :string,
                      :buddy_icon_file_size => :integer,
                     :buddy_icon_updated_at => :datetime,
                        :fav_icon_file_name => :string,
                     :fav_icon_content_type => :string,
                        :fav_icon_file_size => :integer,
                       :fav_icon_updated_at => :datetime,
                      :google_login_enabled => :boolean,
                     :default_tags_checkbox => :string,
                          :message_to_users => :text,
                               :description => :text,
                           :message_for_ads => :text,
                        :message_for_issues => :text,
                       :message_for_network => :text,
                      :message_for_finished => :text,
                        :message_for_points => :text,
                  :message_for_new_priority => :text,
                          :message_for_news => :text
        }},
        {:messages=>{
                      :id => :integer,
               :sender_id => :integer,
            :recipient_id => :integer,
                    :type => :string,
                  :status => :string,
                   :title => :string,
                 :content => :text,
                 :sent_at => :datetime,
                 :read_at => :datetime,
              :created_at => :datetime,
              :updated_at => :datetime,
              :deleted_at => :datetime,
            :content_html => :text
        }},
        {:notifications=>{
                         :id => :integer,
                  :sender_id => :integer,
               :recipient_id => :integer,
                     :status => :string,
                       :type => :string,
              :notifiable_id => :integer,
            :notifiable_type => :string,
                 :created_at => :datetime,
                 :updated_at => :datetime,
                    :sent_at => :datetime,
                    :read_at => :datetime,
               :processed_at => :datetime,
                 :deleted_at => :datetime
        }},
        {:partners=>{
                                    :id => :integer,
                                  :name => :string,
                            :short_name => :string,
                            :picture_id => :integer,
                              :is_optin => :integer,
                            :optin_text => :string,
                           :privacy_url => :string,
                            :created_at => :datetime,
                            :updated_at => :datetime,
                             :is_active => :integer,
                                :status => :string,
                           :users_count => :integer,
                               :website => :string,
                            :deleted_at => :datetime,
                            :ip_address => :string,
                      :is_daily_summary => :boolean,
                       :unsubscribe_url => :string,
                         :subscribe_url => :string,
                        :logo_file_name => :string,
                     :logo_content_type => :string,
                        :logo_file_size => :integer,
                       :logo_updated_at => :datetime,
                          :default_tags => :string,
                   :custom_tag_checkbox => :string,
                 :custom_tag_dropdown_1 => :string,
                 :custom_tag_dropdown_2 => :string,
                  :name_variations_data => :string,
                   :geoblocking_enabled => :boolean,
            :geoblocking_open_countries => :string,
                        :default_locale => :string,
                        :iso_country_id => :integer,
                         :required_tags => :string,
              :message_for_new_priority => :text
        }},
        { :point_qualities => {
                    :id => :integer,
               :user_id => :integer,
              :point_id => :integer,
                 :value => :boolean,
            :created_at => :datetime,
            :updated_at => :datetime}},
        {:pictures=>{
                      :id => :integer,
                    :name => :string,
                  :height => :integer,
                   :width => :integer,
            :content_type => :string,
                    :data => :binary,
              :created_at => :datetime,
              :updated_at => :datetime
        }},
        {:points=>{
                                  :id => :integer,
                         :revision_id => :integer,
                         :priority_id => :integer,
                   :other_priority_id => :integer,
                             :user_id => :integer,
                               :value => :integer,
                     :revisions_count => :integer,
                              :status => :string,
                                :name => :string,
                             :content => :text,
                        :published_at => :datetime,
                          :created_at => :datetime,
                          :updated_at => :datetime,
                             :website => :string,
                     :author_sentence => :string,
                       :helpful_count => :integer,
                     :unhelpful_count => :integer,
                   :discussions_count => :integer,
              :endorser_helpful_count => :integer,
               :opposer_helpful_count => :integer,
            :endorser_unhelpful_count => :integer,
             :opposer_unhelpful_count => :integer,
               :neutral_helpful_count => :integer,
             :neutral_unhelpful_count => :integer,
                               :score => :float,
                      :endorser_score => :float,
                       :opposer_score => :float,
                       :neutral_score => :float,
                        :content_html => :text,
                          :partner_id => :integer,
                         :flags_count => :integer,
                          :user_agent => :string,
                          :ip_address => :string
        }},
        {:priorities=>{
                                  :id => :integer,
                            :position => :integer,
                             :user_id => :integer,
                                :name => :string,
                  :endorsements_count => :integer,
                              :status => :string,
                          :ip_address => :string,
                          :deleted_at => :datetime,
                        :published_at => :datetime,
                          :created_at => :datetime,
                          :updated_at => :datetime,
                        :position_1hr => :integer,
                       :position_24hr => :integer,
                      :position_7days => :integer,
                     :position_30days => :integer,
                 :position_1hr_change => :integer,
                :position_24hr_change => :integer,
               :position_7days_change => :integer,
              :position_30days_change => :integer,
                           :change_id => :integer,
                   :cached_issue_list => :string,
               :up_endorsements_count => :integer,
             :down_endorsements_count => :integer,
                        :points_count => :integer,
                     :up_points_count => :integer,
                   :down_points_count => :integer,
                :neutral_points_count => :integer,
                   :discussions_count => :integer,
                 :relationships_count => :integer,
                       :changes_count => :integer,
                     :official_status => :integer,
                      :official_value => :integer,
                   :status_changed_at => :datetime,
                               :score => :integer,
                  :up_documents_count => :integer,
                :down_documents_count => :integer,
             :neutral_documents_count => :integer,
                     :documents_count => :integer,
                           :short_url => :string,
                    :is_controversial => :boolean,
                      :trending_score => :integer,
                 :controversial_score => :integer,
                     :external_info_1 => :string,
                     :external_info_2 => :string,
                     :external_info_3 => :string,
                       :external_link => :string,
                  :external_presenter => :string,
                         :external_id => :string,
                       :external_name => :string,
                          :partner_id => :integer,
                         :flags_count => :integer,
                         :category_id => :integer,
                          :user_agent => :string,
              :position_endorsed_24hr => :integer,
             :position_endorsed_7days => :integer,
            :position_endorsed_30days => :integer,
             :finished_status_message => :text,
                 :external_session_id => :integer,
             :finished_status_subject => :string,
                :finished_status_date => :date
        }},
        {:priority_charts=>{
                        :id => :integer,
               :priority_id => :integer,
                 :date_year => :integer,
                :date_month => :integer,
                  :date_day => :integer,
                  :position => :integer,
                  :up_count => :integer,
                :down_count => :integer,
                :created_at => :datetime,
                :updated_at => :datetime,
              :volume_count => :integer,
            :change_percent => :float,
                    :change => :integer
        }},
        {:priority_status_change_logs=>{
                     :id => :integer,
            :priority_id => :integer,
             :created_at => :datetime,
             :updated_at => :datetime,
                :content => :text,
                :subject => :string,
                   :date => :date
        }},
        {:profiles=>{
                    :id => :integer,
               :user_id => :integer,
                   :bio => :text,
              :bio_html => :text,
            :created_at => :datetime,
            :updated_at => :datetime
        }},
        {:rankings=>{
                            :id => :integer,
                   :priority_id => :integer,
                       :version => :integer,
                      :position => :integer,
            :endorsements_count => :integer,
                    :created_at => :datetime,
                    :updated_at => :datetime,
                    :partner_id => :integer
        }},
        {:relationships=> {
                           :id => :integer,
                  :priority_id => :integer,
            :other_priority_id => :integer,
                         :type => :string,
                   :percentage => :integer,
                   :created_at => :datetime,
                   :updated_at => :datetime
        }},
        {:sentences=> {
                                     :id => :integer,
            :process_document_element_id => :integer,
                                   :body => :text,
                             :created_at => :datetime,
                             :updated_at => :datetime
        }},
        {:shown_ads=>{
                    :id => :integer,
                 :ad_id => :integer,
               :user_id => :integer,
                 :value => :integer,
            :ip_address => :string,
            :user_agent => :string,
              :referrer => :string,
            :created_at => :datetime,
            :updated_at => :datetime,
            :seen_count => :integer
        }},
        {:revisions=>{
                           :id => :integer,
                     :point_id => :integer,
                      :user_id => :integer,
                        :value => :integer,
                       :status => :string,
                         :name => :string,
                      :content => :text,
                 :published_at => :datetime,
                   :created_at => :datetime,
                   :updated_at => :datetime,
                   :ip_address => :string,
                   :user_agent => :string,
                      :website => :string,
                 :content_diff => :text,
            :other_priority_id => :integer,
                 :content_html => :text
        }},
        {:signups=>{
                    :id => :integer,
            :partner_id => :integer,
               :user_id => :integer,
            :created_at => :datetime,
            :updated_at => :datetime,
            :ip_address => :string
        }},
        {:tag_subscriptions=>{
            :user_id => :integer,
             :tag_id => :integer
        }},
        {:taggings=>{
                       :id => :integer,
                   :tag_id => :integer,
              :taggable_id => :integer,
                :tagger_id => :integer,
              :tagger_type => :string,
            :taggable_type => :string,
                  :context => :string,
               :created_at => :datetime,
               :updated_at => :datetime
        }},
        {:tags=>{
                                   :id => :integer,
                                 :name => :string,
                           :created_at => :datetime,
                           :updated_at => :datetime,
                      :top_priority_id => :integer,
                   :up_endorsers_count => :integer,
                 :down_endorsers_count => :integer,
            :controversial_priority_id => :integer,
                   :rising_priority_id => :integer,
                 :official_priority_id => :integer,
                       :webpages_count => :integer,
                     :priorities_count => :integer,
                          :feeds_count => :integer,
                                :title => :string,
                          :description => :string,
                    :discussions_count => :integer,
                         :points_count => :integer,
                      :documents_count => :integer,
                               :prompt => :string,
                                 :slug => :string,
                           :partner_id => :integer,
                             :tag_type => :integer
        }},
        {:unsubscribes=>{
                                     :id => :integer,
                                :user_id => :integer,
                                  :email => :string,
                                 :reason => :text,
                             :created_at => :datetime,
                             :updated_at => :datetime,
                 :is_comments_subscribed => :boolean,
                    :is_votes_subscribed => :boolean,
            :is_point_changes_subscribed => :boolean,
                 :is_messages_subscribed => :boolean,
                :is_followers_subscribed => :boolean,
                 :is_finished_subscribed => :boolean,
                    :is_admin_subscribed => :boolean
        }},
        {:user_charts=>{
                      :id => :integer,
                 :user_id => :integer,
               :date_year => :integer,
              :date_month => :integer,
                :date_day => :integer,
                :position => :integer,
                :up_count => :integer,
              :down_count => :integer,
            :volume_count => :integer,
              :created_at => :datetime,
              :updated_at => :datetime
        }},
        {:user_contacts=>{
                          :id => :integer,
                     :user_id => :integer,
               :other_user_id => :integer,
                        :name => :string,
                       :email => :string,
                  :created_at => :datetime,
                  :updated_at => :datetime,
                :following_id => :integer,
                :facebook_uid => :integer,
                     :sent_at => :datetime,
                 :accepted_at => :datetime,
            :is_from_realname => :boolean,
                      :status => :string
        }},
        {:user_rankings=>{
                        :id => :integer,
                   :user_id => :integer,
                   :version => :integer,
                  :position => :integer,
            :capitals_count => :integer,
                :created_at => :datetime,
                :updated_at => :datetime
        }},
        {:users=>{
                                      :id => :integer,
                                   :login => :string,
                                   :email => :string,
                        :crypted_password => :string,
                                    :salt => :string,
                              :first_name => :string,
                               :last_name => :string,
                              :created_at => :datetime,
                              :updated_at => :datetime,
                            :activated_at => :datetime,
                         :activation_code => :string,
                          :remember_token => :string,
               :remember_token_expires_at => :datetime,
                              :picture_id => :integer,
                                  :status => :string,
                              :partner_id => :integer,
                              :deleted_at => :datetime,
                              :ip_address => :string,
                             :loggedin_at => :datetime,
                                     :zip => :string,
                              :birth_date => :date,
                           :twitter_login => :string,
                                 :website => :string,
                            :is_mergeable => :boolean,
                             :referral_id => :integer,
                           :is_subscribed => :boolean,
                              :user_agent => :string,
                                :referrer => :string,
                  :is_comments_subscribed => :boolean,
                     :is_votes_subscribed => :boolean,
                               :is_tagger => :boolean,
                      :endorsements_count => :integer,
                   :up_endorsements_count => :integer,
                 :down_endorsements_count => :integer,
                         :up_issues_count => :integer,
                       :down_issues_count => :integer,
                          :comments_count => :integer,
                                   :score => :float,
             :is_point_changes_subscribed => :boolean,
                  :is_messages_subscribed => :boolean,
                          :capitals_count => :integer,
                           :twitter_count => :integer,
                         :followers_count => :integer,
                        :followings_count => :integer,
                          :ignorers_count => :integer,
                         :ignorings_count => :integer,
                           :position_24hr => :integer,
                          :position_7days => :integer,
                         :position_30days => :integer,
                    :position_24hr_change => :integer,
                   :position_7days_change => :integer,
                  :position_30days_change => :integer,
                                :position => :integer,
                 :is_followers_subscribed => :boolean,
                     :partner_referral_id => :integer,
                               :ads_count => :integer,
                           :changes_count => :integer,
                            :google_token => :string,
                      :top_endorsement_id => :integer,
                  :is_finished_subscribed => :boolean,
                          :contacts_count => :integer,
                  :contacts_members_count => :integer,
                  :contacts_invited_count => :integer,
              :contacts_not_invited_count => :integer,
                       :google_crawled_at => :datetime,
                            :facebook_uid => :integer,
                                    :city => :string,
                                   :state => :string,
                         :documents_count => :integer,
                :document_revisions_count => :integer,
                            :points_count => :integer,
                       :index_24hr_change => :float,
                      :index_7days_change => :float,
                     :index_30days_change => :float,
            :received_notifications_count => :integer,
              :unread_notifications_count => :integer,
                                :rss_code => :string,
                   :point_revisions_count => :integer,
                         :qualities_count => :integer,
                      :constituents_count => :integer,
                                 :address => :string,
                          :warnings_count => :integer,
                            :probation_at => :datetime,
                            :suspended_at => :datetime,
                         :referrals_count => :integer,
                                :is_admin => :boolean,
                              :twitter_id => :integer,
                           :twitter_token => :string,
                          :twitter_secret => :string,
                      :twitter_crawled_at => :datetime,
                     :is_admin_subscribed => :boolean,
                    :buddy_icon_file_name => :string,
                 :buddy_icon_content_type => :string,
                    :buddy_icon_file_size => :integer,
                   :buddy_icon_updated_at => :datetime,
                   :is_importing_contacts => :boolean,
                 :imported_contacts_count => :integer,
                             :facebook_id => :integer,
                         :reports_enabled => :boolean,
                     :reports_discussions => :boolean,
                       :reports_questions => :boolean,
                       :reports_documents => :boolean,
                        :reports_interval => :integer,
                        :last_sent_report => :datetime,
              :geoblocking_open_countries => :string,
                          :identifier_url => :string,
                               :age_group => :string,
                               :post_code => :string,
                               :my_gender => :string,
                        :report_frequency => :integer
        }} ]

    delete_columns_per_table =
        {:activities=> {
                                  :vote_id => :integer,
                                :change_id => :integer,
                              :document_id => :integer,
                     :document_revision_id => :integer},
        :governments=>{
                          :official_user_id => :integer,
                  :official_user_short_name => :string,
                  :briefing_name => :string,
                            :is_legislators => :boolean,
                           :documents_count => :integer,
            :official_user_priorities_count => :integer,
        },
        :points=>{
               :neutral_helpful_count => :integer,
             :neutral_unhelpful_count => :integer,
                       :neutral_score => :float,
        },
        :priorities=>{
                           :change_id => :integer,
                       :changes_count => :integer,
                  :up_documents_count => :integer,
                :down_documents_count => :integer,
             :neutral_documents_count => :integer,
                     :documents_count => :integer,
        },
        :tags=>{
                 :official_priority_id => :integer,
                      :documents_count => :integer,
        },
        :unsubscribes=>{
                    :is_votes_subscribed => :boolean,
        },

        :users=>{
                           :changes_count => :integer,
                         :documents_count => :integer,
                :document_revisions_count => :integer,
                :constituents_count => :integer,
                :is_votes_subscribed => :boolean,
                :reports_questions => :boolean,
                :reports_documents => :boolean,

        } }

    puts "mysqldump -u yrpri_production -h 213.229.119.227 -p yrpri_production #{used_list.map {|x| x}.join(" ")}}"

    delete_columns_per_table.each do |table,columns|
      columns.each do |column|
        puts "ALTER TABLE #{table} DROP #{column[0].to_s};"
      end
    end

    puts ""

    used_columns_per_table.each do |entries|
      entries.each do |table,columns|
        columns.each do |column|
          #puts "#{table} #{column}"
          if delete_columns_per_table[table.to_sym] and delete_columns_per_table[table.to_sym][column[0].to_sym]
            #puts "IN DELETE next #{column[0]}"
            next
          end

          if change_to_name = shall_we_change(column[0].to_s)
            puts "ALTER TABLE #{table} CHANGE COLUMN #{column[0].to_s} #{change_to_name} #{change_to_mysql_text(column[1].to_s)};"
          end
        end
      end
    end

    puts ""

    table_rename_list.each do |renameer|
      puts "RENAME TABLE #{renameer[0]} TO #{renameer[1]};"
    end

    puts ""
    puts "DROP TABLE messages;"
    puts ""

    used_list.each do |mtable|
      #puts "#{mtable.classify}"
    end

    used_list.each do |mtable|
      if shall_we_change(mtable)
        puts "DELETE FROM #{shall_we_change(mtable)};"
      else
        puts "DELETE FROM #{mtable};"
      end
    end



  end

  desc "Seed desc"
  task :seed_descriptions => :environment do
    Idea.all.each do |idea|
      text = "#{idea.points.first.content_html[0..272]}.."
      idea.description = text
      idea.save
    end
  end

  desc "Parse xml map"
  task :parse_xml_map => :environment do
    doc = Nokogiri::HTML(File.open(Rails.root+"public/world_countries_kml.xml"))
    all_iso_countries = IsoCountry.all.map {|c| c.country_english_name}
    all_found = []
    all_not_found = []
    doc.xpath('//placemark').each_with_index do |x,i|
      puts x.search("name").text
      if country = IsoCountry.find_by_country_english_name(x.search("name").text)
        puts "FOUND"
        all_found << x.search("name").text
        all_coords = []
        x.search("coordinates").each do |coord|
          all_coords << coord.text
        end
        puts country.map_coordinates = all_coords.to_s
        country.save
      else
        puts "NOT FOUND"
        all_not_found << x.search("name").text
      end
      puts x.search("coordinates").text.strip
    end
    puts "Found #{all_found.length}"
    puts "-----------------------------------------------"
    puts all_found
    puts "Not Found #{all_not_found.length}"
    puts "-----------------------------------------------"
    puts all_not_found
    puts "Missing #{(all_iso_countries-all_found).length}"
    puts "-----------------------------------------------"
    puts (all_iso_countries-all_found).sort
  end

  desc "Update idea change logs"
  task :update_change_logs => :environment do
    IdeaStatusChangeLog.transaction do
      IdeaStatusChangeLog.all.each do |status|
        new_subject = help.strip_tags(status.content)
        if new_subject.empty?
          status.destroy
        else
          status.subject = new_subject
          status.content = nil
          status.date = status.updated_at
          status.save
        end
      end
    end
  end

  desc "tweak videos"
  task :tweak_videos => :environment do
    ProcessSpeechMasterVideo.all.each do |m|
      if m.id<9
        m.published = true
        m.in_processing = false
        m.save
      elsif m.id<11
        m.published = false
        m.in_processing = true
        m.save
      end
    end
    ProcessSpeechVideo.all.each dom|
      if m.id<281
        m.published = true
        m.in_processing = false
        m.save
      end
    end
  end

  desc "reset process documents"
  task :reset_process_documents => :environment do
    connection = ActiveRecord::Base.connection();
    connection.execute("DELETE FROM process_documents;")
    connection.execute("DELETE FROM process_document_elements;")
  end


  desc "reset database"
  task :reset_database_YES => :environment do
    puts "1"
    connection = ActiveRecord::Base.connection();
    connection.execute("DELETE FROM activities;")
    connection.execute("DELETE FROM ads;")
    connection.execute("DELETE FROM blasts;")
    connection.execute("DELETE FROM capitals;")
    connection.execute("DELETE FROM changes;")
    connection.execute("DELETE FROM client_applications;")
    connection.execute("DELETE FROM categories;")
    connection.execute("DELETE FROM generated_proposal_elements;")
    connection.execute("DELETE FROM generated_proposals;")
    connection.execute("DELETE FROM comments;")
    #connection.execute("DELETE FROM constituents;")
    connection.execute("DELETE FROM delayed_jobs;")
    connection.execute("DELETE FROM document_qualities;")
    connection.execute("DELETE FROM document_revisions;")
    connection.execute("DELETE FROM documents;")
    connection.execute("DELETE FROM endorsements;")
    puts "2"
    connection.execute("DELETE FROM facebook_templates;")
    connection.execute("DELETE FROM feeds;")
    connection.execute("DELETE FROM following_discussions;")
    connection.execute("DELETE FROM followings;")
    connection.execute("DELETE FROM legislators;")
    connection.execute("DELETE FROM letters;")
    connection.execute("DELETE FROM messages;")
    connection.execute("DELETE FROM notifications;")
    connection.execute("DELETE FROM pages;")
    connection.execute("DELETE FROM sub_instances;")
    connection.execute("DELETE FROM pictures;")
    connection.execute("DELETE FROM point_qualities;")
    connection.execute("DELETE FROM points;")
    connection.execute("DELETE FROM ideas;")
    connection.execute("DELETE FROM idea_charts;")
    puts "3"
    connection.execute("DELETE FROM idea_status_change_logs;")
    connection.execute("DELETE FROM process_discussions;")
    connection.execute("DELETE FROM process_document_elements;")
    connection.execute("DELETE FROM process_document_states;")
    connection.execute("DELETE FROM process_document_types;")
    connection.execute("DELETE FROM process_documents;")
    connection.execute("DELETE FROM process_speech_master_videos;")
    connection.execute("DELETE FROM process_speech_videos;")
    connection.execute("DELETE FROM process_types;")
    connection.execute("DELETE FROM profiles;")
    connection.execute("DELETE FROM rankings;")
    connection.execute("DELETE FROM ratings;")
    puts "4"
    connection.execute("DELETE FROM relationships;")
    connection.execute("DELETE FROM revisions;")
    connection.execute("DELETE FROM shown_ads;")
    connection.execute("DELETE FROM signups;")
    connection.execute("DELETE FROM tag_subscriptions;")
    connection.execute("DELETE FROM taggings;")
    connection.execute("DELETE FROM tags;")
    connection.execute("DELETE FROM unsubscribes;")
    connection.execute("DELETE FROM user_charts;")
    connection.execute("DELETE FROM user_contacts;")
    connection.execute("DELETE FROM user_rankings;")
    connection.execute("DELETE FROM users WHERE id != 1;")
    connection.execute("DELETE FROM votes;")
    connection.execute("DELETE FROM webpages;")
    puts "5"

    connection.execute("OPTIMIZE TABLE activities;")
    connection.execute("OPTIMIZE TABLE ads;")
    connection.execute("OPTIMIZE TABLE blasts;")
    connection.execute("OPTIMIZE TABLE capitals;")
    connection.execute("OPTIMIZE TABLE changes;")
    connection.execute("OPTIMIZE TABLE comments;")
    #connection.execute("OPTIMIZE TABLE constituents;")
    connection.execute("OPTIMIZE TABLE delayed_jobs;")
    connection.execute("OPTIMIZE TABLE document_qualities;")
    connection.execute("OPTIMIZE TABLE document_revisions;")
    puts "6"
    connection.execute("OPTIMIZE TABLE documents;")
    connection.execute("OPTIMIZE TABLE endorsements;")
    connection.execute("OPTIMIZE TABLE facebook_templates;")
    connection.execute("OPTIMIZE TABLE feeds;")
    connection.execute("OPTIMIZE TABLE following_discussions;")
    connection.execute("OPTIMIZE TABLE followings;")
    connection.execute("OPTIMIZE TABLE legislators;")
    connection.execute("OPTIMIZE TABLE letters;")
    connection.execute("OPTIMIZE TABLE messages;")
    connection.execute("OPTIMIZE TABLE notifications;")
    connection.execute("OPTIMIZE TABLE pages;")
    connection.execute("OPTIMIZE TABLE sub_instances;")
    connection.execute("OPTIMIZE TABLE pictures;")
    connection.execute("OPTIMIZE TABLE point_qualities;")
    puts "7"
    connection.execute("OPTIMIZE TABLE points;")
    connection.execute("OPTIMIZE TABLE ideas;")
    connection.execute("OPTIMIZE TABLE idea_charts;")
    connection.execute("OPTIMIZE TABLE idea_status_change_logs;")
    connection.execute("OPTIMIZE TABLE process_types;")
    puts "8"
    connection.execute("OPTIMIZE TABLE profiles;")
    connection.execute("OPTIMIZE TABLE rankings;")
    connection.execute("OPTIMIZE TABLE ratings;")
    connection.execute("OPTIMIZE TABLE relationships;")
    connection.execute("OPTIMIZE TABLE revisions;")
    connection.execute("OPTIMIZE TABLE shown_ads;")
    connection.execute("OPTIMIZE TABLE signups;")
    connection.execute("OPTIMIZE TABLE tag_subscriptions;")
    connection.execute("OPTIMIZE TABLE taggings;")
    connection.execute("OPTIMIZE TABLE tags;")
    puts "9"
    connection.execute("OPTIMIZE TABLE unsubscribes;")
    connection.execute("OPTIMIZE TABLE user_charts;")
    connection.execute("OPTIMIZE TABLE user_contacts;")
    connection.execute("OPTIMIZE TABLE user_rankings;")
    puts "10"
    connection.execute("OPTIMIZE TABLE users;")
    connection.execute("OPTIMIZE TABLE votes;")
    connection.execute("OPTIMIZE TABLE webpages;")
    puts "11"
      #categories
      #color_schemes
      #instances
      #portlet_containers
      #portlet_positions
      #portlet_template_categories
      #portlet_templates
      #portlets
      #schema_migrations
      #simple_captcha_data
      #widgets

    u=User.first
    u.endorsements_count = 0
    u.up_endorsements_count = 0
    u.down_endorsements_count = 0
    u.up_issues_count = 0
    u.down_issues_count = 0
    u.comments_count = 0
    u.score = 0.1
    u.capitals_count = 0
    u.twitter_count = 0
    u.followers_count = 0
    u.followings_count = 0
    u.ignorers_count = 0
    u.ignorings_count = 0
    u.position_24hr = 0
    u.position_7days = 0
    u.position_30days = 0
    u.position_24hr_delta = 0
    u.position_7days_delta = 0
    u.position_30days_delta = 0
    u.position = 0
    u.ads_count = 0
    u.changes_count = 0
    u.top_endorsement_id = nil
    u.contacts_count = 0
    u.contacts_members_count = 0
    u.contacts_invited_count = 0
    u.contacts_not_invited_count = 0
    u.documents_count = 0
    u.document_revisions_count = 0
    u.points_count = 0
    u.index_24hr_delta = 0.0
    u.index_7days_delta = 0.0
    u.index_30days_delta = 0.0
    u.received_notifications_count = 0
    u.unread_notifications_count = 0
    u.point_revisions_count = 0
    u.qualities_count = 0
    #u.constituents_count = 0
    u.warnings_count = 0
    u.referrals_count = 0
    u.imported_contacts_count = 0
    u.save(false)
    if Instance.last.default_tags_checkbox
      Instance.last.default_tags_checkbox.split(",").each do |t|
        tag=Tag.new
        tag.name = t
        tag.save
      end
    end
  end

  desc "delete activities that don't have objects which are now nil"
  task :abandoned_activities => :environment do
    # not sure if this works yet
    activities = Activity.find_by_sql("SELECT * from activities where NOT EXISTS (select * from users where activities.other_user_id = users.id or activities.other_user_id is null)")
  end
  
  desc "fix default branches for users"
  task :default_branch => :environment do
    Instance.all.last.update_user_default_branch
  end
  
  desc "fix endorsement counts"
  task :endorsement_counts => :environment do
    Instance.current = Instance.all.last
    for p in Idea.find(:all)
      p.endorsements_count = p.endorsements.active_and_inactive.size
      p.up_endorsements_count = p.endorsements.endorsing.active_and_inactive.size
      p.down_endorsements_count = p.endorsements.opposing.active_and_inactive.size
      p.save(:validate => false)      
    end
  end
  
  desc "fix endorsement positions"
  task :endorsement_positions => :environment do
    Instance.current = Instance.all.last
    for u in User.active.at_least_one_endorsement.all(:order => "users.id asc")
      row = 0
      for e in u.endorsements.active.by_position
        row += 1
        e.update_attribute(:position,row) unless e.position == row
        u.update_attribute(:top_endorsement_id,e.id) if u.top_endorsement_id != e.id and row == 1
      end
      puts u.login
    end
  end
  
  desc "fix endorsement scores"
  task :endorsement_scores => :environment do
    Instance.current = Instance.all.last
    Endorsement.active.find_in_batches(:include => :user) do |endorsement_group|
      for e in endorsement_group
        current_score = e.score
        new_score = e.calculate_score
        e.update_attribute(:score, new_score) if new_score != current_score
      end
    end      
  end
  
  desc "fix duplicate endorsements"
  task :duplicate_endorsements => :environment do
    Instance.current = Instance.all.last
    # get users with duplicate endorsements
    endorsements = Endorsement.find_by_sql("
        select user_id, idea_id, count(*) as num_times
        from endorsements
        group by user_id,idea_id
  	    having count(*) > 1
    ")
    for e in endorsements
      user = e.user
      idea = e.idea
      multiple_endorsements = user.endorsements.active.find(:all, :conditions => ["idea_id = ?",idea.id], :order => "endorsements.position")
      if multiple_endorsements.length > 1
        for c in 1..multiple_endorsements.length-1
          multiple_endorsements[c].destroy
        end
      end
    end
  end  
  
  desc "fix duplicate top idea activities"
  task :duplicate_idea1_activities => :environment do
    Instance.current = Instance.all.last
    models = [ActivityIdea1,ActivityIdea1Opposed]
    for model in models
      dupes = Activity.find_by_sql("select user_id, idea_id, count(*) as number from activities
      where type = '#{model}'
      group by user_id, idea_id
      order by count(*) desc")
      for a in dupes
        if a.number.to_i > 1
          activities = model.find(:all, :conditions => ["user_id = ? and idea_id = ?",a.user_id,a.idea_id], :order => "changed_at desc")
          for c in 1..activities.length-1
            activities[c].destroy
          end
        end
      end
    end
  end
  
  desc "fix discussion counts"
  task :discussion_counts => :environment do
    Instance.current = Instance.all.last
    ideas = Idea.find(:all)
    for p in ideas
      p.update_attribute(:discussions_count,p.activities.discussions.for_all_users.active.size) if p.activities.discussions.for_all_users.active.size != p.discussions_count
    end
    points = Point.find(:all)
    for p in points
      p.update_attribute(:discussions_count,p.activities.discussions.for_all_users.active.size) if p.activities.discussions.for_all_users.active.size != p.discussions_count
    end
    docs = Document.find(:all)
    for d in docs
      d.update_attribute(:discussions_count, d.activities.discussions.for_all_users.active.size) if d.activities.discussions.for_all_users.active.size != d.discussions_count
    end
  end
  
  desc "fix tag counts"
  task :tag_counts => :environment do
    Instance.current = Instance.all.last
    for t in Tag.all
      t.update_counts
      t.save(:validate => false)
    end
  end  
  
  desc "fix branch counts"
  task :branch_counts => :environment do
    Instance.current = Instance.all.last
    for b in Branch.all
      b.update_counts
      b.save(:validate => false)
    end
    Branch.expire_cache
  end  

  desc "fix comment participant dupes"
  task :comment_participants => :environment do
    Instance.current = Instance.all.last
    Activity.record_timestamps = false
    user_id = nil
    activity_id = nil
    for ac in ActivityCommentParticipant.active.find(:all, :order => "activity_id asc, user_id asc")
      if activity_id == ac.activity_id and user_id == ac.user_id
        ac.destroy
      else
        activity_id = ac.activity_id
        user_id = ac.user_id
        ac.update_attribute(:comments_count,ac.activity.comments.published.count(:conditions => ["user_id = ?",user_id]))
      end
    end
    Activity.record_timestamps = true
  end
  
  desc "fix helpful counts"
  task :helpful_counts => :environment do
    Instance.current = Instance.all.last
    endorser_helpful_points = Point.find_by_sql("SELECT points.id, points.endorser_helpful_count, count(*) as number
    FROM points INNER JOIN endorsements ON points.idea_id = endorsements.idea_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value  =1
    and point_qualities.value = true
    group by points.id, points.endorser_helpful_count
    having number <> endorser_helpful_count")
    for point in endorser_helpful_points
      point.update_attribute("endorser_helpful_count",point.number)
    end

    endorser_helpful_points = Document.find_by_sql("SELECT documents.id, documents.endorser_helpful_count, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.idea_id = endorsements.idea_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value  =1
    and document_qualities.value = 1
    group by documents.id, documents.endorser_helpful_count
    having number <> endorser_helpful_count")
    for doc in endorser_helpful_points
      doc.update_attribute("endorser_helpful_count",doc.number)
    end    

    opposer_helpful_points = Point.find_by_sql("SELECT points.id, points.opposer_helpful_count, count(*) as number
    FROM points INNER JOIN endorsements ON points.idea_id = endorsements.idea_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value = -1
    and point_qualities.value = true
    group by points.id, points.opposer_helpful_count
    having number <> opposer_helpful_count")
    for point in opposer_helpful_points
      point.update_attribute("opposer_helpful_count",point.number)
    end  

    opposer_helpful_points = Document.find_by_sql("SELECT documents.id, documents.opposer_helpful_count, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.idea_id = endorsements.idea_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value = -1
    and document_qualities.value = 1
    group by documents.id, documents.opposer_helpful_count
    having number <> opposer_helpful_count")
    for doc in opposer_helpful_points
      doc.update_attribute("opposer_helpful_count",doc.number)
    end    

    endorser_unhelpful_points = Point.find_by_sql("SELECT points.id, points.endorser_unhelpful_count, count(*) as number
    FROM points INNER JOIN endorsements ON points.idea_id = endorsements.idea_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value = 1
    and point_qualities.value = false
    group by points.id, points.endorser_unhelpful_count
    having number <> endorser_unhelpful_count")
    for point in endorser_unhelpful_points
      point.update_attribute("endorser_unhelpful_count",point.number)
    end  

    endorser_unhelpful_points = Document.find_by_sql("SELECT documents.id, documents.endorser_unhelpful_count, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.idea_id = endorsements.idea_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value  =1
    and document_qualities.value = 0
    group by documents.id, documents.endorser_unhelpful_count
    having number <> endorser_unhelpful_count")
    for doc in endorser_unhelpful_points
      doc.update_attribute("endorser_unhelpful_count",doc.number)
    end    

    opposer_unhelpful_points = Point.find_by_sql("SELECT points.id, points.opposer_unhelpful_count, count(*) as number
    FROM points INNER JOIN endorsements ON points.idea_id = endorsements.idea_id
    	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
    where endorsements.value = -1
    and point_qualities.value = false
    group by points.id, points.opposer_unhelpful_count
    having number <> opposer_unhelpful_count")
    for point in opposer_unhelpful_points
      point.update_attribute("opposer_unhelpful_count",point.number)
    end      

    opposer_unhelpful_points = Document.find_by_sql("SELECT documents.id, documents.opposer_unhelpful_count, count(*) as number
    FROM documents INNER JOIN endorsements ON documents.idea_id = endorsements.idea_id
    	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
    where endorsements.value = -1
    and document_qualities.value = 0
    group by documents.id, documents.opposer_unhelpful_count
    having number <> opposer_unhelpful_count")
    for doc in opposer_unhelpful_points
      doc.update_attribute("opposer_unhelpful_count",doc.number)
    end  

    #neutral counts
    Point.connection.execute("update points
    set neutral_unhelpful_count = unhelpful_count - endorser_unhelpful_count - opposer_unhelpful_count,
    neutral_helpful_count =  helpful_count - endorser_helpful_count - opposer_helpful_count")
    Document.connection.execute("update documents
    set neutral_unhelpful_count = unhelpful_count - endorser_unhelpful_count - opposer_unhelpful_count,
    neutral_helpful_count =  helpful_count - endorser_helpful_count - opposer_helpful_count")           
  end  
  
  desc "fix user counts"
  task :user_counts => :environment do
    Instance.current = Instance.all.last
    users = User.find(:all)
    for u in users
      u.update_counts
      u.save(:validate => false)
    end
  end
  
  desc "update official_status on ideas"
  task :official_status => :environment do
    Instance.current = Instance.all.last
    if Instance.current.has_official?
      Idea.connection.execute("update ideas set official_value = 1
      where official_value <> 1 and id in (select idea_id from endorsements where user_id = #{govt.official_user_id} and value > 0 and status = 'active')")
      Idea.connection.execute("update ideas set official_value = -1
      where official_value <> -1 and id in (select idea_id from endorsements where user_id = #{govt.official_user_id} and value < 0 and status = 'active')")
      Idea.connection.execute("update ideas set official_value = 0
      where official_value <> 0 and id not in (select idea_id from endorsements where user_id = #{govt.official_user_id} and status = 'active')")
    end
  end  
  
  desc "re-process doc & point diffs"
  task :diffs => :environment do
    Instance.current = Instance.all.last
    models = [Document,Point]
    for model in models
      for p in model.all
        revisions = p.revisions.by_recently_created
        puts p.name
        for row in 0..revisions.length-1
          if row == revisions.length-1
            revisions[row].content_diff = revisions[row].content
          else
            revisions[row].content_diff = HTMLDiff.diff(revisions[row+1].content,revisions[row].content)
          end
          revisions[row].save(:validate => false)
        end
      end
    end
  end
  
  desc "run the auto_html processing on all objects. used in case of changes to auto_html filtering rules"
  task :content_html => :environment do
    Instance.current = Instance.all.last
    models = [Comment,Message,Point,Revision,Document,DocumentRevision]
    for model in models
      for p in model.all
        p.auto_html_prepare
        p.update_attribute(:content_html, p.content_html)
      end
    end
  end
  
  desc "this will fix the activity changed_ats"
  task :activities_changed_at => :environment do
    Instance.current = Instance.all.last
    Activity.connection.execute("UPDATE activities set changed_at = created_at")
    for a in Activity.active.discussions.all
      if a.comments.published.size > 0
        a.update_attribute(:changed_at, a.comments.published.by_recently_created.first.created_at)
      end
    end
  end  
  
  desc "make all commenters on a discussion follow that discussion, this should only be done once"
  task :discussion_followers => :environment do
    Instance.current = Instance.all.last
    for a in Activity.discussions.active.all
      for u in a.commenters
        a.followings.find_or_create_by_user_id(u.id)
      end
      a.followings.find_or_create_by_user_id(a.user_id) # add the owner of the activity too
    end
    Activity.connection.execute("DELETE FROM activities where type = 'ActivityDiscussionFollowingNew'")
  end
  
  desc "branch endorsements"
  task :branch_endorsements => :environment do
    Instance.current = Instance.all.last
    for branch in Branch.all
      endorsement_scores = Endorsement.active.find(:all, 
        :select => "endorsements.idea_id, sum((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value) as score, count(*) as endorsements_number",
        :joins => "endorsements INNER JOIN ideas ON ideas.id = endorsements.idea_id",
        :conditions => ["endorsements.user_id in (?) and endorsements.position <= #{Endorsement.max_position}",branch.user_ids], 
        :group => "endorsements.idea_id",
        :order => "score desc")
      down_endorsement_counts = Endorsement.active.find(:all, 
        :select => "endorsements.idea_id, count(*) as endorsements_number",
        :joins => "endorsements INNER JOIN ideas ON ideas.id = endorsements.idea_id",
        :conditions => ["endorsements.value = -1 and endorsements.user_id in (?)",branch.user_ids], 
        :group => "endorsements.idea_id")
      up_endorsement_counts = Endorsement.active.find(:all, 
        :select => "endorsements.idea_id, count(*) as endorsements_number",
        :joins => "endorsements INNER JOIN ideas ON ideas.id = endorsements.idea_id",
        :conditions => ["endorsements.value = 1 and endorsements.user_id in (?)",branch.user_ids], 
        :group => "endorsements.idea_id")
      
      row = 0
      for e in endorsement_scores
        row += 1
        be = branch.endorsements.find_or_create_by_idea_id(e.idea_id.to_i)
        be.score = e.score.to_i
        be.endorsements_count = e.endorsements_number.to_i
        be.position = row
        down = down_endorsement_counts.detect {|d| d.idea_id == e.idea_id.to_i }
        if down
          be.down_endorsements_count = down.endorsements_number.to_i
        else
          be.down_endorsements_count = 0
        end
        up = up_endorsement_counts.detect {|d| d.idea_id == e.idea_id.to_i }
        if up
          be.up_endorsements_count = up.endorsements_number.to_i
        else
          be.up_endorsements_count = 0
        end            
        be.save(:validate => false)
      end          
    end
  end
  
  desc "idea charts"
  task :idea_charts => :environment do
    [14,13,12,11,10,9,8,7,6,5,4,3,2,1].each do |daysminus|
      date = (Time.now-daysminus.days)-4.hours-1.day
      last_week_date = (Time.now-daysminus.days)-4.hours-8.day
      puts "Processing: #{date}"
      previous_date = date-1.day
      start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      start_date_last_week = last_week_date.year.to_s + "-" + last_week_date.month.to_s + "-" + last_week_date.day.to_s
      end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
      if true or IdeaChart.count(:conditions => ["date_year = ? and date_month = ? and date_day = ?", date.year, date.month, date.day]) == 0  # check to see if it's already been done for yesterday
        puts "Doing chart"
        ideas = Idea.published.find(:all)
        for p in ideas
          # find the ranking
          puts "Idea id: #{p.id}"
          r = p.rankings.find(:all, :conditions => ["rankings.created_at between ? and ?",start_date,end_date], :order => "created_at desc",:limit => 1)
          unless r.any?
            puts "Using last 8 days"
            r = p.rankings.find(:all, :conditions => ["rankings.created_at between ? and ?",start_date_last_week,end_date], :order => "created_at desc",:limit => 1)
          end
          if r.any?
            puts "#{date} - Processing chart position #{r[0].position}!"
            c = p.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
            if not c
              c = IdeaChart.new(:idea => p, :date_year => date.year, :date_month => date.month, :date_day => date.day)
              puts "Creating new chart"
            end
            c.position = r[0].position
            c.up_count = p.endorsements.active.endorsing.count(:conditions => ["endorsements.created_at between ? and ?",start_date,end_date])
            c.down_count = p.endorsements.active.opposing.count(:conditions => ["endorsements.created_at between ? and ?",start_date,end_date])
            c.volume_count = c.up_count + c.down_count
            previous = p.charts.find_by_date_year_and_date_month_and_date_day(previous_date.year,previous_date.month,previous_date.day) 
            if previous
              c.change = previous.position-c.position
              c.change_percent = (c.change.to_f/previous.position.to_f)          
            end
            c.save
            if p.created_at+2.days > Time.now # within last two days, check to see if we've given them their priroity debut activity
              ActivityIdeaDebut.create(:user => p.user, :idea => p, :position => p.position) unless ActivityIdeaDebut.find_by_idea_id(p.id)
            end        
          end
          Rails.cache.delete('views/idea_chart-' + p.id.to_s)
        end
        Rails.cache.delete('views/total_volume_chart') # reset the daily volume chart
#        for u in User.active.at_least_one_endorsement.all
#          u.index_24hr_delta = u.index_delta_percent(2)
#          u.index_7days_delta = u.index_delta_percent(7)
#          u.index_30days_delta = u.index_delta_percent(30)
#          u.save(:validate => false)
#          u.expire_charts
#        end       
      end
    end
  end
