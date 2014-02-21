# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper

  def first_image_url_from_text(text)
    image_url = nil
    URI.extract(text).each do |url|
      #TODO: Check if its really an image url
      url = url.downcase
      image_url = url if url.include?(".png") or url.include?(".jpg") or url.include?(".jpg")
    end
    image_url
  end

  def currency_with_unit(amount,currency)
    if currency=="USD"
      number_to_currency amount, :unit=>"$", :precision=>0, :locale=>"en"
    elsif currency=="EUR"
      number_to_currency amount, :unit=>"EUR", :precision=>0, :locale=>"en"
    elsif currency=="GBP"
      number_to_currency amount, :unit=>"GBP", :precision=>0, :locale=>"en"
    elsif currency=="ISK"
      number_to_currency amount, :unit=>"kr.", :precision=>0, format: "%n %u", :locale=>"en"
    end
  end


  def get_locale_demo_host(domain)
    locale_host = "https://demo-#{I18n.locale}"
    if SubInstance.find_by_short_name("demo-#{I18n.locale}")
      locale_host+domain
    else
      "https://demo"+domain
    end
  end

  def calc_language_completion(count)
    if current_user and current_user.is_root? and count>0
      complete = Tolk::Locale.find_by_name("en").translations.count
      " (#{((count/complete)*100).to_i}%)"
    else
      ""
    end
  end

  def get_locale_options
    out = ""
    all_locales = Tolk::Locale.order("weight asc,name desc").all
    if SubInstance.current.default_locale
      default_locale = Tolk::Locale.find_by_name(SubInstance.current.default_locale)
      if default_locale
        all_locales.delete(default_locale)
        all_locales.insert(0,default_locale)
      end
    end
    all_locales.uniq.each do |locale|
      next if locale.translations.count<210 and locale.name!=SubInstance.current.default_locale
      language_name = Tolk::Config.mapping[locale.name]
      #out += link_to("#{language_name}#{calc_language_completion(locale.translations.count)}", "#{url_for(:locale => locale.name)}")
      out += "<li>"
      out += link_to language_name, "/?locale=#{locale.name}"
      out += "</li>"
    end
    out.html_safe
  end

  def tr(a,b="",c={})
    a.localized_text(c)
  end

  def current_facebook_user_if_on_facebook
    ret_user = nil
    begin
      ret_user = current_facebook_user
    rescue Mogli::Client::OAuthException
      return nil
    end
    ret_user
  end

  def my_simple_format(text, html_options={}, options={})
    text = ''.html_safe if text.nil?
    start_tag = tag('p', html_options, true)
    text = sanitize(text) unless options[:sanitize] == false
    text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
    text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")  # 2+ newline  -> paragraph
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
    text.insert 0, start_tag
    text.html_safe.safe_concat("</p>")
  end

 def last_weekday_of_the_month_at_noon(now_date,original_now_date=nil)
   original_now_date = now_date unless original_now_date
   current_date = now_date.end_of_month
   while [0,6].include?(current_date.wday)
     current_date = current_date-1
   end
   current_date = current_date.midnight+12.hours
   if current_date<=original_now_date
     last_weekday_of_the_month_at_noon(now_date.next_month,original_now_date)
   else
     current_date
   end
 end

 def options_for_select_simple(options,selected=nil,blank=nil)
    out = ""
    out+="<option value=\"\"#{selected==nil ? "selected" : ""}>#{blank}</option>" if blank
    options.each do |a,b|
      out+="<option value=\"#{b}\"#{b==selected ? "selected" : ""}>#{a}</option>"
    end
    out.html_safe
  end

  def get_random_logo
    logo_filename = Pathname.new(Dir.glob(Rails.root.join("app","assets","images","logos").to_s+'/*').sort_by { rand }.first).basename
    %Q{<img src="/logos/#{logo_filename}"/>}.html_safe
  end

  def tg(text)
    "#{text}"
  end

  def translate_facet_option(option)
    if option=="Comment"
      tr("comments","helpers/application")
    elsif option=="Point"
      tr("Points","helpers/application")
    elsif option=="Idea"
      tr("ideas","helpers/application")
    elsif option=="Document"
      tr("document","helpers/application")
    else
      option
    end
  end
  
  def make_quoted(tag_name)
    "'#{tag_name}'"
  end

  def subscribed_to_tag?(user_id,tag_id)
    if TagSubscription.find(:first, :conditions=>["user_id = ? AND tag_id = ?",user_id,tag_id])
      true
    else
      false
    end
  end

  def time_ago(time, options = {})
    if true or request.xhr?
      (distance_of_time_in_words_to_now(time) + ' '+tr("ago","helpers/application")).html_safe
    else
      options[:class] ||= "timeago"
      content_tag(:abbr, time.to_s, options.merge(:title => time.getutc.iso8601)) if time
    end
  end  
  
  def flash_div *keys
    f = keys.collect { |key| content_tag(:div, link_to("x","#", :class => "close_notify") + content_tag(:span, flash[key]), :class => "flash_#{key}") if flash[key] }.join
    keys.collect { |key| flash[key] = nil }
    return f.html_safe
  end

  def revisions_sentence(user)
    return "" if user.points_count+user.documents_count+user.revisions_count == 0
    r = []
    r << link_to(tr("{count} points","notifications", :count => user.points_count), points_user_url(user)) if user.points_count > 0
    r << link_to(tr("{count} documents", "notifications", :count => user.documents_count), documents_user_url(user)) if user.documents_count > 0
    r << tr("{count} revisions", "notifications",  :count => user.revisions_count) if user.revisions_count > 0
    tr("Revisions: {sentence}", "notifications", :sentence => r.to_sentence)
  end
  
  def notifications_sentence(notifications)
    return "" if notifications.empty?
    r = []
    for u in notifications
      if u[0] == 'NotificationWarning1'
        r << link_to(tr("{warning_number}. warning","notifications", :warning_number=>1), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationWarning2'
        r << link_to(tr("{warning_number}. warning","notifications", :warning_number=>2), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationWarning3'
        r << link_to(tr("{warning_number}. warning","notifications", :warning_number=>3), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationWarning4'
        r << link_to(tr("{warning_number}. warning","notifications", :warning_number=>4), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationMessage' 
        r << tr("{count} {sentence}", "notifications", :count => u[1], :sentence =>messages_sentence(current_user.received_notifications.messages.unread.count(:group => [:sender], :order => "count_all desc")))
      elsif u[0] == 'NotificationCommentFlagged'
        r << link_to(tr("{count} comment flag(s)", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationIdeaFlagged'
        r << link_to(tr("{count} idea flag(s)", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationPointFlagged'
        r << link_to(tr("{count} point flag(s)", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationComment' 
        r << link_to(tr("{count} new comment(s)", "notifications", :count => u[1]), :controller => "feed", :action => "your_discussions")
      elsif u[0] == 'NotificationProfileBulletin'
        r << link_to(tr("{count} new bulletin(s)", "notifications", :count => u[1]), current_user)
      elsif u[0] == 'NotificationFollower' 
        r << link_to(tr("{count} new follower(s)", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationInvitationAccepted' 
        r << link_to(tr("{count} new invitation(s) accepted", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationContactJoined' 
        r << link_to(tr("{count} new contact(s) joined", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationDocumentRevisions' 
        r << link_to(tr("{count} document revision(s)", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationPointRevision' 
        r << link_to(tr("{count} point revision(s)", "notifications", :count => u[1]), :controller => "inbox", :action => "notifications")
      elsif u[0] == 'NotificationIdeaFinished'
        r << link_to(tr("{count} prioritie(s) finished", "notifications", :count => u[1]), yours_finished_ideas_url)
      elsif false and u[0] == 'NotificationChangeVote' 
        r << link_to(tr("{count} merger vote(s)", "notifications",:count => u[1]), :controller => "feed", :action => "changes_voting")
      elsif false and u[0] == 'NotificationChangeProposed' 
        r << link_to(tr("{count} merger(s) proposed", "notifications", :count => u[1]), :controller => "feed", :action => "changes_voting")
      end 
    end     
    return "" if r.empty?
    tr("<h5>Notifications</h5>{sentence}", "notifications", :sentence => r.to_sentence)
  end
  
  def messages_sentence(messages)
    return "" if messages.empty?
    r = []
    for m in messages
      r << link_to(m[0].name, user_messages_url(m[0]))
    end
    r.to_sentence
  end
  
  def relationship_sentence(relationships)
    return "" if relationships.empty?
    r = []
		for relationship in relationships
			if relationship.class == RelationshipUndecidedEndorsed
				r << tr("{percentage} undeclared", "relationships", :percentage => number_to_percentage(relationship.percentage, :precision => 0))
			elsif relationship.class == RelationshipOpposerEndorsed
				r << tr("{percentage} opposers", "relationships", :percentage => number_to_percentage(relationship.percentage, :precision => 0))
			elsif relationship.class == RelationshipEndorserEndorsed
				r << tr("{percentage} endorsers", "relationships", :percentage => number_to_percentage(relationship.percentage, :precision => 0))
			end
		end
		t('ideas.relationship.name', :sentence => r.to_sentence)
  end
  
  def tags_sentence(list)
    r = []
    for tag_name in list.split(', ')
      tag = current_tags.detect{|t| t.name.downcase == tag_name.downcase}
			r << link_to(tr(tag.title,"model/category"), tag.show_url) if tag
		end
		r.to_sentence.html_safe
  end
    
  def relationship_tags_sentence(list)
		t('ideas.relationship.tags_sentence', :sentence => tags_sentence(list))
  end
  
  def rss_url(url)
    return "" unless false #url
    s = '<span class="rss_feed"><a href="' + url + '">'
    s += image_tag "feed-icon-14x14.png", :size => "14x14", :border => 0, :alt => 'rss-icon'
    s += '</a></span>'
    return s.html_safe
  end
  
  def agenda_change(user,period,precision=0)
    if period == '7days'
		  user_last = user.index_7days_delta*100
		elsif period == '24hr'
		  user_last = user.index_24hr_delta*100
		elsif period == '30days'
		  user_last = user.index_30days_delta*100
		end
		if user_last < 0.005 and user_last > -0.005
		  s = '<div class="nochange">' + tr("unchanged","agenda_change") + '</div>'
		elsif user_last.abs == user_last
		  s = '<div class="gainer">+'
		  s += number_to_percentage(user_last, :precision => precision)
		  s += '</div>'
		else
		  s = '<div class="loser">'
		  s += number_to_percentage(user_last, :precision => precision)
		  s += '</div>'
		end
		return s.html_safe
  end

  def official_status(idea)
  	if idea.is_failed?
  		out = '<span class="status_opposed">' + idea.official_status_name + '</span>'
  	elsif idea.is_successful?
  		out = '<span class="status_endorsed">' + idea.official_status_name + '</span>'
  	elsif idea.is_compromised?
  		out = '<span class="status_in_progress">' + idea.official_status_name + '</span>'
  	elsif idea.is_intheworks?
  		out = '<span>' + idea.official_status_name + '</span>'
    else
      out = ""
  	end
  	out.html_safe if out
  end
  
  def liquidize(content, arguments)
    Liquid::Template.parse(content).render(arguments, :filters => [LiquidFilters])
  end

  def time_in_words(time)
    return "" unless time
    s = ""
    s += ' '+tr("in","helpers/application") if time > Time.now
    s += distance_of_time_in_words_to_now(time).gsub("about","")
    s += ' '+tr("ago","helpers/application") if time < Time.now
    return s.html_safe
  end

  def get_short_star_rating(asset,br=false)
    "#{sprintf("%.1f",asset.rating)}/5.0 #{br ? "<br>" : ""} <small>(#{asset.ratings.size} #{tr("votes counted", "vote_texts")})</small>".html_safe
  end
  
#  def will_paginate_with_i18n(collection, options = {}) 
#    will_paginate_without_i18n(collection, options.merge(:previous_label => I18n.t(:prev_t), :next_label => I18n.t(:next_t))) 
#  end 

#  alias_method_chain :will_paginate, :i18n  

  def escape_t(text)
    text.gsub("\"","")
  end

  def sub_instance_link(short_name)
    SubInstance.find_by_short_name(short_name).show_url
  end
end
