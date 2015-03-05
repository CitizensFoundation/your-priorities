class UserMailer < Devise::Mailer
    
  helper :application

  # so DelayedJob will know how to make absolute urls
  def default_url_options
    if @activity and @activity.sub_instance_id
      { host:  "#{SubInstance.find(@activity.sub_instance_id).short_name}.#{Instance.last.domain_name}", :protocol => 'https'}.merge(super)
    elsif @user and @user.sub_instance_id
      { host: "#{SubInstance.find(@user.sub_instance_id).short_name}.#{Instance.last.domain_name}", :protocol => 'https'}.merge(super)
    else
      { host: "www.#{Instance.last.domain_name}" , :protocol => 'https'}.merge(super)
    end
  end

  def thank_you_for_payment(user, payment, plan, next_payment, args={})
    @current_plan = plan
    @recipient = @resource = @sender = @recipient = @user = user
    @payment = payment
    @next_payment = next_payment
    @instance = Instance.last
    setup_locale
    @sub_instance = SubInstance.where(:id=>user.sub_instance_id).first
    @instance_name = @sub_instance.name

    attachments.inline['logo.png'] = get_email_banner
    mail  to: @user.email,
          reply_to: @instance.admin_email,
          from: "#{@instance.name} <#{@instance.admin_email}>",
          subject: tr("Thank you for your payment on {instance_name}","email", :instance_name => @instance.name) do |format|
      format.text { render text: convert_to_text(render_to_string(__method__, formats: [:html])) }
      format.html
    end
  end

  def invitation_instructions(user, token, opts={})
    @token = token
    @recipient = @resource = @sender = @recipient = @user = user
    @instance = Instance.last
    invited_by = User.where(:id=>user.invited_by_id).first
    setup_locale(invited_by)
    Rails.logger.debug("INVITED_BY USER: #{invited_by.inspect}")
    @sender_name = invited_by.login
    sub_instance = SubInstance.where(:id=>invited_by.sub_instance_id).first
    @instance_name = sub_instance.name

    attachments.inline['logo.png'] = get_email_banner
    mail  to: @user.email,
          reply_to: @instance.admin_email,
          from: "#{@instance.name} <#{@instance.admin_email}>",
          subject: tr("You have been invited to join {sub_instance_name} on {instance_name}","email", :sub_instance_name => sub_instance.name, :instance_name => @instance.name) do |format|
      format.text { render text: convert_to_text(render_to_string(__method__, formats: [:html])) }
      format.html
    end
  end

  def new_sub_instance(user, args={})
    @recipient = @resource = @sender = @recipient = @user = user
    @instance = Instance.last
    setup_locale
    @sub_instance = SubInstance.where(:id=>user.sub_instance_id).first
    @instance_name = @sub_instance.name

    attachments.inline['logo.png'] = get_email_banner
    mail  to: @user.email,
          reply_to: @instance.admin_email,
          from: "#{@instance.name} <#{@instance.admin_email}>",
          subject: tr("{sub_instance_name} is ready on {instance_name}","email", :sub_instance_name => @sub_instance.name, :instance_name => @instance.name) do |format|
      format.text { render text: convert_to_text(render_to_string(__method__, formats: [:html])) }
      format.html
    end
  end

  def confirmation_instructions(user, opts={})
    @recipient = @user = user
    setup_locale
    @instance = Instance.last
    attachments.inline['logo.png'] = get_email_banner
    mail  to: "#{@user.real_name.titleize} <#{@user.email}>",
          reply_to: @instance.admin_email,
          from: "#{@instance.name} <#{@instance.admin_email}>",
          subject: tr("Thank you for registering at {instance_name}","email", :instance_name => @instance.name) do |format|
      format.text { render text: convert_to_text(render_to_string(__method__, formats: [:html])) }
      format.html
    end 
  end

  def reset_password_instructions(user, token, opts={})
    @token = token
    @recipient = @user = user
    setup_locale
    @instance = Instance.last
    attachments.inline['logo.png'] = get_email_banner
    mail  to: "#{@user.real_name.titleize} <#{@user.email}>",
          reply_to: @instance.admin_email,
          from: "#{@instance.name} <#{@instance.admin_email}>",
          subject: tr("Password reset instructions for {instance_name}","email", :instance_name => @instance.name) do |format|
      format.text { render text: convert_to_text(render_to_string(__method__, formats: [:html])) }
      format.html
    end
  end

  def welcome(user)
    @recipient = @user = user
    setup_locale
    @instance = Instance.last
    recipients  = "#{user.real_name.titleize} <#{user.email}>"
    attachments.inline['logo.png'] = get_email_banner
    mail :to=>recipients,
         :reply_to => Instance.last.admin_email,
         :from => "#{Instance.last.name} <#{Instance.last.admin_email}>",
         :subject=>tr("Thank you for registering at {instance_name}","email", :instance_name => Instance.last.name) do |format|
           format.text { render :text=>convert_to_text(render_to_string("welcome", formats: [:html])) }
           format.html
         end
  end

  def category_changed(user,idea,category_from,category_to)
    @recipient = @user = user
    @idea = idea
    @category_from = category_from.name
    @category_to = category_to.name
    setup_locale(user)
    @instance = Instance.last
    attachments.inline['logo.png'] = get_email_banner
    recipient = "#{user.real_name.titleize} <#{user.email}>"
    mail to:       recipient,
         reply_to: Instance.last.admin_email,
         from:     "#{Instance.last.name} <#{Instance.last.admin_email}>",
         subject:  tr("The category of your idea {idea} has been changed","email", :idea => idea.name) do |format|
      format.text { render text: convert_to_text(render_to_string("category_changed", formats: [:html])) }
      format.html
    end
  end

  def sub_instance_changed(user,idea,from_sub_instance,to_sub_instance,status_message)
    @recipient = @user = user
    @idea = idea
    @from_sub_instance = from_sub_instance.name
    @to_sub_instance = to_sub_instance.name
    @status_message = status_message
    setup_locale(user)
    @instance = Instance.last
    attachments.inline['logo.png'] = get_email_banner
    recipient = "#{user.real_name.titleize} <#{user.email}>"
    mail to:       recipient,
         reply_to: Instance.last.admin_email,
         from:     "#{Instance.last.name} <#{Instance.last.admin_email}>",
         subject:  tr("Your idea {idea} has been moved","email", :idea => idea.name) do |format|
      format.text { render text: convert_to_text(render_to_string("sub_instance_changed", formats: [:html])) }
      format.html
    end
  end

  def lost_or_gained_capital(user, activity, point_difference, sub_instance_id)
    instance_name = setup_instance_name(sub_instance_id)
    @instance = Instance.last
    @activity = activity
    @point_difference = point_difference
    @recipient = @user = user
    setup_locale
    recipient = "#{user.real_name.titleize} <#{user.email}>"
    attachments.inline['logo.png'] = get_email_banner

    if point_difference > 0
      subject = tr("You just gained {points} social point(s) at {instance_name}", "email", points: point_difference.abs, :instance_name => Instance.last.name)
    else
      subject = tr("You just lost {points} social point(s) at {instance_name}", "email", points: point_difference.abs, :instance_name => Instance.last.name)
    end

    mail to:       recipient,
         reply_to: Instance.last.admin_email,
         from:     "#{Instance.last.name} <#{Instance.last.admin_email}>",
         subject:  subject do |format|
      format.text { render text: convert_to_text(render_to_string("lost_or_gained_capital", formats: [:html])) }
      format.html { render :template=>"user_mailer/master_template", :locals=>{:subject=>subject, :partial_name=>"lost_or_gained_capital", :instance_name=>instance_name}}
    end
  end

  def idea_status_update(idea, status, status_date, status_subject, status_message, user, position)
    @idea = idea
    @instance = Instance.last
    @status = status
    @date = status_date
    @status_subject = status_subject
    @message = status_message
    @recipient = @user = user
    setup_locale
    if position == 1
      @support_or_endorse_text = tr("which you support", "email")
    else
      @support_or_endorse_text = tr("which you oppose", "email")
    end
    attachments.inline['logo.png'] = get_email_banner
    recipient = "#{user.real_name.titleize} <#{user.email}>"
    mail to:       recipient,
         reply_to: Instance.last.admin_email,
         from:     "#{Instance.last.name} <#{Instance.last.admin_email}>",
         subject:  tr("The status of {idea} has been changed","email", :idea => idea.name) do |format|
      format.text { render text: convert_to_text(render_to_string("idea_status_update", formats: [:html])) }
      format.html
    end
  end

  def user_report(user, important, important_to_followers, near_top, frequency)
    setup_locale
    freq_to_word = {
        2 => tr("Weekly","email"),
        1 => tr("Monthly","email")
    }
    freq = freq_to_word[frequency]
    subject = tr("{frequency} status report from {instance_name}", 'email', frequency: freq, instance_name: Instance.last.name)
    @instance = Instance.last
    @important = important
    @important_to_followers = important_to_followers
    @near_top = near_top
    @recipient = @user = user
    setup_locale
    recipient = "#{user.real_name.titleize} <#{user.email}>"
    attachments.inline['logo.png'] = get_email_banner
    mail to:       recipient,
         reply_to: Instance.last.admin_email,
         from:     "#{Instance.last.name} <#{Instance.last.admin_email}>",
         subject:  subject do |format|
      format.text { render text: convert_to_text(render_to_string("user_report", formats: [:html])) }
      format.html
    end

  end

  def invitation(user,sender_name,to_name,to_email)
    @sender = @recipient = @user = user
    setup_locale
    @instance = Instance.last
    @sender_name = sender_name
    @to_name = to_name
    @to_email = to_email
    @recipients = ""
    @recipients += to_name + ' ' if to_name
    @recipients += '<' + to_email + '>'
    attachments.inline['logo.png'] = get_email_banner
    mail :to => @recipients,
         :reply_to => Instance.last.admin_email,
         :from => "#{Instance.last.name} <#{Instance.last.admin_email}>",
         :subject => tr("Invitation from {sender_name} to join {instance_name}","email", :sender_name=>sender_name, :instance_name => Instance.last.name) do |format|
           format.text { render :text=>convert_to_text(render_to_string("invitation", formats: [:html])) }
           format.html
         end
  end  

  def new_password(user,new_password)
    @recipient = @user = user
    setup_locale
    @new_password = new_password
    @instance = Instance.last
    recipients  = "#{user.real_name.titleize} <#{user.email}>"
    attachments.inline['logo.png'] = get_email_banner
    mail :to=>recipients,
         :reply_to => Instance.last.admin_email,
         :from => "#{Instance.last.name} <#{Instance.last.admin_email}>",
         :subject => tr("Your new temporary password","email") do |format|
           format.text { render :text=>convert_to_text(render_to_string("new_password", formats: [:html])) }
           format.html
         end
  end
  
  def notification(n,sender,recipient,notifiable)
    if notifiable.respond_to?(:sub_instance_id) and notifiable.sub_instance_id
      sub_instance_id = notifiable.sub_instance_id
    else
      sub_instance_id = nil
    end
    instance_name = setup_instance_name(sub_instance_id)
    @n = @notification = n
    @sender = sender
    @instance = Instance.last
    user = @user = @recipient = recipient
    setup_locale
    @notifiable = notifiable
    subject = @notification.name
    Rails.logger.debug("Notification class: #{@n} #{@n.class.to_s}  #{@n.inspect} notifiable: #{@notifiable}")
    recipients  = "#{user.real_name.titleize} <#{user.email}>"
    attachments.inline['logo.png'] = get_email_banner
    mail :to => recipients,
         :reply_to => Instance.last.admin_email,
         :from => "#{Instance.last.name} <#{Instance.last.admin_email}>",
         :subject => subject do |format|
      #format.text { render :text=>convert_to_text(render_to_string("user_mailer/notifications/#{@n.class.to_s.underscore}", formats: [:html])) }
      format.html { render :template=>"user_mailer/master_template", :locals=>{:subject=>subject, :partial_name=>"user_mailer/notifications/#{@n.class.to_s.underscore}", :instance_name=>instance_name}}
    end
  end
  
#   def new_change_vote(sender,recipient,vote)
#     setup_notification(recipient)
#     @subject = "Your " + Instance.last.name + " vote is needed: " + vote.change.idea.name
#     @body[:vote] = vote
#     @body[:change] = vote.change
#     @body[:recipient] = recipient
#     @body[:sender] = sender
#   end 
  
  protected

  def setup_sub_instance_from_current
    if @activity and @activity.sub_instance_id
      SubInstance.current = SubInstance.find(@activity.sub_instance_id)
    elsif @user and @user.sub_instance_id
      SubInstance.current = SubInstance.find(@user.sub_instance_id)
    elsif @recipient and @recipient.sub_instance_id
      SubInstance.current = SubInstance.find(@user.sub_instance_id)
    else
      SubInstance.current = SubInstance.where(:short_name=>"default")
    end
  end

  def setup_locale(locale_user=nil)
    setup_sub_instance_from_current
    if locale_user and locale_user.last_locale and locale_user.last_locale!=""
      I18n.locale = locale_user.last_locale
    elsif @recipient and @recipient.last_locale and @recipient.last_locale!=""
      I18n.locale = @recipient.last_locale
    elsif Instance.current.default_locale
      I18n.locale = Instance.current.default_locale
    else
      I18n.locale = "en"
    end
    Rails.logger.info("email locale: #{I18n.locale} locale user: #{locale_user.id}") if locale_user
    tr8n_current_locale = I18n.locale
  end

  def setup_notification(user)
      @recipients  = "#{user.login} <#{user.email}>"
      @from        = "#{Instance.last.name} <#{Instance.last.email}>"
      headers        "Reply-to" => Instance.last.email
      @sent_on     = Time.now
      @content_type = "text/html"     
      @body[:root_url] = 'http://' + Instance.last.base_url_w_sub_instance + '/'
    end

  private

    def setup_instance_name(sub_instance_id)
      @instance = Instance.current
      if sub_instance_id
        SubInstance.current=SubInstance.where(:id=>sub_instance_id).first
        instance_name = SubInstance.current.name if SubInstance.current
      else
        instance_name = @instance.name
      end
    end

    def get_email_banner
      if Instance.first.has_email_banner?
        if Rails.env.development?
          File.open(Rails.root.join("public#{Instance.first.email_banner.url.split("?")[0]}")).read
        else
          open(Instance.first.email_banner.url).read
        end
      end
    end

    # Returns the text in UTF-8 format with all HTML tags removed
    # From: https://github.com/jefflab/mail_style/tree/master/lib
    # TODO:
    #  - add support for DL, OL
    def convert_to_text(html, line_length = 65, from_charset = 'UTF-8')
      txt = html

      # decode HTML entities
      he = HTMLEntities.new
      begin
        txt = he.decode(txt)
      rescue
        txt = txt
      end

      # handle headings (H1-H6)
      txt.gsub!(/[ \t]*<h([0-9]+)[^>]*>(.*)<\/h[0-9]+>/i) do |s|
        hlevel = $1.to_i
        # cleanup text inside of headings
        htext = $2.gsub(/<\/?[^>]*>/i, '').strip
        hlength = (htext.length > line_length ?
                    line_length :
                    htext.length)

        case hlevel
          when 1   # H1, asterisks above and below
            ('*' * hlength) + "\n" + htext + "\n" + ('*' * hlength) + "\n"
          when 2   # H1, dashes above and below
            ('-' * hlength) + "\n" + htext + "\n" + ('-' * hlength) + "\n"
          else     # H3-H6, dashes below
            htext + "\n" + ('-' * htext.length) + "\n"
        end
      end

      # links
      txt.gsub!(/<a.*href=\"([^\"]*)\"[^>]*>(.*)<\/a>/i) do |s|
        $2.strip + ' ( ' + $1.strip + ' )'
      end

      # lists -- TODO: should handle ordered lists
      txt.gsub!(/[\s]*(<li[^>]*>)[\s]*/i, '* ')
      # list not followed by a newline
      txt.gsub!(/<\/li>[\s]*(?![\n])/i, "\n")

      # paragraphs and line breaks
      txt.gsub!(/<\/p>/i, "\n\n")
      txt.gsub!(/<br[\/ ]*>/i, "\n")

      # strip remaining tags
      txt.gsub!(/<\/?[^>]*>/, '')

      # wrap text
#      txt = r.format(('[' * line_length), txt)

      # remove linefeeds (\r\n and \r -> \n)
      txt.gsub!(/\r\n?/, "\n")

      # strip extra spaces
#      txt.gsub!(/\302\240+/, " ") # non-breaking spaces -> spaces
      txt.gsub!(/\n[ \t]+/, "\n") # space at start of lines
      txt.gsub!(/[ \t]+\n/, "\n") # space at end of lines

      # no more than two consecutive newlines
      txt.gsub!(/[\n]{3,}/, "\n\n")

      txt.strip
    end          
end
