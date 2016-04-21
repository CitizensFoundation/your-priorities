require 'json'

namespace :export_to_new_version do

  desc "Save a json file with everything"
  task :export_all => :environment do


    users = []
    groups = []
    categories = []
    posts = []
    post_revisions = []
    post_status_changes = []
    endorsements = []
    points = []
    point_revisions = []
    point_qualities = []
    comments = []
    promotions = []
    pages = []
    activities = []
    followings = []

    puts "Processing INSTANCE"
    instance = Instance.first

    domain = {
        name: instance.name,
        domain_name: instance.domain_name,
        description: instance.description,
        created_at: instance.created_at,
        google_analytics_code: instance.google_analytics_code,
        default_locale: instance.default_locale,
        access: 0
    }

    # GROUPS
    puts "Processing GROUPS"
    SubInstance.unscoped.all.each do |group|
      private_instance = false
      if group.subscription_enabled? and group.subscription
        private_instance = group.subscription.plan.private_instance
      end
      groups << {
          id: group.id,
          name: group.name,
          description: group.description,
          hostname: group.short_name,
          default_locale: group.default_locale,
          message_for_new_idea: group.message_for_new_idea,
          message_to_users: group.message_to_users,
          google_analytics_code: group.google_analytics_code,
          iso_country_id: group.iso_country_id,
          access: 0,
          user_id: 1,
          logo_url: group.logo.url(:icon_full),
          header_url: group.top_banner.url(:icon_full), 
          private_instance: private_instance,
          created_at: group.created_at
      }
    end

    # CATEGORIES
    puts "Processing CATEGORIES"
    Category.unscoped.all.each do |category|
      categories << {
          id: category.id,
          name: category.name,
          description: category.description,
          group_id: category.sub_instance_id,
          icon_url: category.icon.url(:icon_200),
          created_at: category.created_at
      }
    end

    # POSTS
    puts "Processing POSTS"
    Idea.unscoped.all.each do |post|
      posts << {
          id: post.id,
          content_type: 0,
          name: post.name,
          description: post.description,
          status: post.status,
          official_status: post.official_status,
          counter_flags: post.flags_count,
          group_id: post.sub_instance_id,
          user_id: post.user_id,
          ip_address: post.ip_address,
          user_agent: post.user_agent,
          category_id: post.category_id,
          created_at: post.created_at
      }
    end

    # POST_REVISIONS
    puts "Processing POST_REVISIONS"
    IdeaRevision.unscoped.all.each do |post_revision|
      puts post_revision.name
      post_revisions << {
          id: post_revision.id,
          name: post_revision.name,
          description: post_revision.description,
          status: post_revision.status,
          user_id: post_revision.user_id,
          ip_address: post_revision.ip_address,
          user_agent: post_revision.user_agent,
          created_at: post_revision.created_at
      }
    end

    # POST_STATUS_CHANGES
    puts "Processing POST_STATUS_CHANGES"
    IdeaStatusChangeLog.unscoped.all.each do |post_status_change|
      post_status_changes << {
          id: post_status_change.id,
          content: post_status_change.content,
          subject: post_status_change.subject,
          post_id: post_status_change.idea_id,
          published_at: post_status_change.date,
          created_at: post_status_change.created_at
      }
    end

    # ENDORSEMENTS
    puts "Processing ENDORSEMENTS"
    Endorsement.unscoped.all.each do |endorsement|
      endorsements << {
          id: endorsement.id,
          post_id: endorsement.idea_id,
          user_id: endorsement.user_id,
          value: endorsement.value,
          status: endorsement.status,
          ip_address: endorsement.ip_address,
          created_at: endorsement.created_at
      }
    end

    # POINTS
    puts "Processing POINTS"
    Point.unscoped.all.each do |point|
      points << {
          id: point.id,
          post_id: point.idea_id,
          user_id: point.user_id,
          value: point.value,
          status: point.status,
          name: point.name,
          content: point.content,
          counter_flags: point.flags_count,
          counter_revisions: point.revisions_count,
          ip_address: point.ip_address,
          user_agent: point.user_agent,
          created_at: point.created_at
      }
    end

    # POINT_REVISION
    puts "Processing POINT_REVISION"
    Revision.unscoped.all.each do |point_revision|
      point_revisions << {
          id: point_revision.id,
          point_id: point_revision.point_id,
          user_id: point_revision.user_id,
          value: point_revision.value,
          status: point_revision.status,
          name: point_revision.name,
          content: point_revision.content,
          ip_address: point_revision.ip_address,
          user_agent: point_revision.user_agent,
          created_at: point_revision.created_at
      }
    end

    # POINT QUALITY
    puts "Processing POINT_QUALITY"
    PointQuality.unscoped.all.each do |point_quality|
      point_qualities << {
          id: point_quality.id,
          point_id: point_quality.point_id,
          user_id: point_quality.user_id,
          value: point_quality.value,
          created_at: point_quality.created_at
      }
    end

    # COMMENTS
    puts "Processing COMMENTS"
    Comment.unscoped.all.each do |comment|
      comments << {
          id: comment.id,
          post_id: comment.activity.idea_id,
          user_id: comment.user_id,
          status: comment.status,
          content: comment.content,
          counter_flags: comment.flags_count,
          ip_address: comment.ip_address,
          user_agent: comment.user_agent,
          created_at: comment.created_at
      }
    end

    # PROMOTIONS
    puts "Processing PROMOTIONS"
    Ad.unscoped.all.each do |promotion|
      promotions << {
          id: promotion.id,
          post_id: promotion.idea_id,
          user_id: promotion.user_id,
          status: promotion.status,
          content: promotion.content,
          cost: promotion.cost,
          per_viewer_cost: promotion.per_user_cost,
          spent: promotion.spent,
          position: promotion.position,
          finished_at: promotion.finished_at,
          counter_up_endorsements: promotion.yes_count,
          counter_down_endorsements: promotion.no_count,
          counter_skips: promotion.skip_count,
          counter_views: promotion.shown_ads_count,
          created_at: promotion.created_at
      }
    end

    # PAGES
    puts "Processing PAGES"
    Page.unscoped.all.each do |page|
      pages << {
          id: page.id,
          title: page.title,
          name: page.name,
          group_id: page.sub_instance_id,
          user_id: 1,
          weight: page.weight,
          content: page.content,
          created_at: page.created_at
      }
    end

    # FOLLOWINGS
    puts "Processing FOLLOWINGS"
    Following.unscoped.all.each do |following|
      followings << {
          id: following.id,
          user_id: following.user_id,
          other_user_id: following.other_user_id,
          value: following.value,
          created_at: following.created_at
      }
    end

    # USERS
    puts "Processing USERS"
    User.unscoped.all.each do |user|
      users << {
          id: user.id,
          name: user.login,
          email: user.email,
          status: user.status,
          group_id: user.sub_instance_id,
          facebook_id: user.facebook_uid,
          twitter_id: user.twitter_id,
          created_at: user.created_at,
          encrypted_password: user.encrypted_password,
          buddy_icon: user.buddy_icon.url(:original),
          is_admin: user.is_admin,
          first_name: user.first_name,
          last_name: user.last_name,
          social_points: user.capitals_count,
          ssn: user.ssn,
          age_group: user.age_group,
          post_code: user.post_code,
          my_gender: user.my_gender
      }
    end

    # ACTIVITIES
    puts "Processing ACTIVITIES"
    Activity.unscoped.all.each do |activity|
      activities << {
          id: activity.id,
          type: activity.type,
          group_id: activity.sub_instance_id,
          post_id: activity.idea_id,
          point_id: activity.point_id,
          user_id: activity.user_id,
          promotion_id: activity.ad_id,
          post_status_change_id: activity.idea_status_change_log_id,
          status: activity.status,
          created_at: activity.created_at
      }
    end

    hash = {
        "domain" => domain,
        "users" => users,
        "groups" => groups,
        "categories" => categories,
        "posts" => posts,
        "post_revisions" => post_revisions,
        "post_status_changes" => post_status_changes,
        "endorsements" => endorsements,
        "points" => points,
        "point_revisions" => point_revisions,
        "point_qualities" => point_qualities,
        "comments" => comments,
        "promotions" => promotions,
        "pages" => pages,
        "followings" => followings,
        "activities" => activities
    }

    File.open("db/export.json", "w") do |f|
      f.write(hash.to_json)
    end
  end

end
