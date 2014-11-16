class Notification < ActiveRecord::Base

  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"

  belongs_to :notifiable, :polymorphic => true

  scope :active, :conditions => "notifications.status <> 'removed'"
  scope :unprocessed, :conditions => "notifications.processed_at IS NULL"
  scope :sent, :conditions => "notifications.status in('sent','read')"
  scope :read, :conditions => "notifications.status = 'read'"
  scope :unread, :conditions => "notifications.status in ('sent','unsent')"

  scope :messages, :conditions => "notifications.type = 'NotificationMessage'"
  scope :comments, :conditions => "notifications.type = 'NotificationComment'"  

  scope :by_recently_created, :order => "notifications.created_at desc"  
  scope :by_recently_sent, :order => "notifications.sent_at desc"
  scope :by_oldest_sent, :order => "notifications.sent_at asc"  

  cattr_reader :per_page
  @@per_page = 30

  def notifiable
    notifiable_type.constantize.unscoped{ super }
  end

  include Workflow
  workflow_column :status
  workflow do
    state :unsent do
      event :send_email, transitions_to: :sent_email
    end
    state :sent_email do
      event :read, transitions_to: :read
      event :remove, transitions_to: :removed
    end
    state :read do
      event :remove, transitions_to: :removed
    end
    state :removed do
      event :unremove, transitions_to: :read, meta: { validates_presence_of: [:read_at] }
      event :unremove, transitions_to: :sent_email, meta: { validates_presence_of: [:sent_at] }
      event :unremove, transitions_to: :unsent
    end
  end

  after_create :add_counts
  after_commit :queue_sending

  def add_counts
    recipient.increment!(:unread_notifications_count)
    recipient.increment!(:received_notifications_count)
  end
  
  def queue_sending
    Rails.logger.debug("In queue_sending")
    self.send_email!
  end

  def on_sent_email_entry(new_state, event)
    Rails.logger.debug("In send!")
    self.removed_at = nil
    self.processed_at = Time.now
    Rails.logger.debug("In send! #{is_recipient_subscribed?} #{recipient.has_email?} #{recipient.is_active?}")
    if (is_recipient_subscribed? and recipient.has_email? and recipient.is_active?) or
        (is_recipient_subscribed? and recipient.has_email? and self.class == NotificationWarning4)
      self.sent_at = Time.now
      UserMailer.notification(self,sender,recipient,notifiable).deliver
    end
    #if recipient.has_facebook?
    #  self.sent_at = Time.now
    #  Facebooker::Session.create.send_notification([recipient.facebook_uid],fbml)
    #end
    save(:validate => false)
  end

  def on_read_entry(new_state, event)
    self.removed_at = nil
    self.read_at = Time.now
    save(:validate => false)
    recipient.decrement!(:unread_notifications_count)
  end
  
  def on_removed_entry(new_state, event)
    self.removed_at = Time.now
    save(:validate => false)
    recipient.decrement!(:received_notifications_count)
    recipient.decrement!(:unread_notifications_count) if status != 'read'
  end
  
  def unread?
    ['sent','unsent'].include?(self.status)
  end

  def notifiable_name
    if notifiable
      notifiable.name
    else
      my_notifiable = eval("#{notifiable_type}.unscoped.where(:id=>#{notifiable_id}).first")
      if my_notifiable
        my_notifiable.name
      else
        Rails.logger.error("Notification: No notifiable for #{self.id}")
        tr("not found","here")
      end
    end
  end

  def recipient_name
    recipient.name if recipient
  end

  def recipient_name=(n)
    self.recipient = User.find_by_login(n) unless n.blank?
  end
  
  def sender_name
    if sender
      sender.name
    else
      my_sender = User.unscoped.where(:id=>sender_id).first
      if my_sender
        my_sender.name
      else
        Rails.logger.error("Notification: No sender for #{self.id}")
        tr("not found","here")
      end
    end
  end
  
  def sender_name=(n)
    self.sender = User.find_by_login(n) unless n.blank?
  end  
  


  # you can override this in subclasses to specify a different rule for whether the person is subscribed
  def is_recipient_subscribed?
    recipient.report_frequency != 0
  end

end

class NotificationChangeProposed < Notification
  
  def name
    tr("{sender_name} proposed {new_idea_name} acquire {idea_name}", "model/notification", :sender_name => sender.name, :idea_name => notifiable.idea_name, :new_idea_name => notifiable.new_idea.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end
  
end

class NotificationComment < Notification
  
  def name
    if notifiable.activity==nil
      Rails.logger.error("No activity for #{self.inspect}")
      "Unknown"
    elsif notifiable.activity.has_point?
      tr("{sender_name} commented on {comment_name}", "model/notification", :sender_name => sender.name, :comment_name => notifiable.activity.point.name)      
    elsif notifiable.activity.has_idea?
      tr("{sender_name} commented on {comment_name}", "model/notification", :sender_name => sender.name, :comment_name => notifiable.activity.idea.name)
    elsif notifiable.activity.class == ActivityBulletinProfileNew
      tr("{sender_name} left a comment on {user_name} profile", "model/notification", :sender_name => sender.name, :user_name => notifiable.activity.user.name)
    else
      if notifiable.activity.user_id == recipient_id
        tr("{sender_name} commented on your activity", "model/notification", :sender_name => sender.name, :comment_name => notifiable.activity.name)              
      else
        tr("{sender_name} commented on {user_name} activity", "model/notification", :sender_name => sender.name, :comment_name => notifiable.activity.name, :user_name => notifiable.activity.user.name)     
      end 
    end      
  end
  
  def is_recipient_subscribed?
    recipient.is_comments_subscribed?
  end  
  
end

class NotificationCommentFlagged < Notification
  
  def name
    tr("{sender_name} flagged a comment by {user_name}", "model/notification", :sender_name => sender.name, :user_name => notifiable.user.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end

class NotificationContactJoined < Notification
  
  def name
    tr("{sender_name} just joined", "model/notification", :sender_name => sender.name)
    sender.login + " just joined"
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end

class NotificationFollower < Notification
  
  def name
    tr("{sender_name} is now following your updates", "model/notification", :sender_name => sender.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_followers_subscribed?
  end  
  
end

class NotificationInvitationAccepted < Notification
  
  def name
    tr("{sender_name} accepted your invitation to join {instance_name}", "model/notification", :sender_name => sender.name, :instance_name => Instance.current.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_followers_subscribed?
  end
  
end

class NotificationMessage < Notification
  
  def name
    tr("{sender_name} sent you a private message", "model/notification", :sender_name => sender.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_messages_subscribed?
  end  
  
end

class NotificationIdeaFlagged < Notification
  
  def name
    tr("{sender_name} flagged {idea_name} for review", "model/notification", :sender_name => sender.name, :idea_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end

class NotificationPointFlagged < Notification
  
  def name
    tr("{sender_name} flagged {point_name} for review", "model/notification", :sender_name => sender.name, :point_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end

class NotificationProfileBulletin < Notification
  
  def name
    tr("{sender_name} posted a bulletin to your profile", "model/notification", :sender_name => sender.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_messages_subscribed?
  end  
  
end

class NotificationPointRevision < Notification
  
  def name
    tr("{sender_name} revised {point_name}", "model/notification", :sender_name => sender.name, :point_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_point_changes_subscribed?
  end  
  
end

class NotificationIdeaRevision < Notification
  
  def name
    tr("{sender_name} revised {idea_name}", "model/notification", :sender_name => sender.name, :idea_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_idea_changes_subscribed?
  end  
  
end

class NotificationIdeaFinished < Notification
  
  def name
    if notifiable.idea.is_successful?
       tr("{idea_name} was completed successfully", "model/notification", :idea_name => notifiable.idea.name)
    elsif notifiable.idea.is_compromised?
      tr("{idea_name} was completed with a compromise", "model/notification", :idea_name => notifiable.idea.name)
    elsif notifiable.idea.is_failed?
      tr("{idea_name} failed", "model/notification", :idea_name => notifiable.idea.name)
    elsif notifiable.idea.is_intheworks?
      tr("{idea_name} is in the works", "model/notification", :idea_name => notifiable.idea.name)
    end
  end
  
  def is_recipient_subscribed?
    recipient.is_finished_subscribed?
  end  
  
end

class NotificationWarning1 < Notification
  
  def name
    tr("This is your first warning for violating the site rules.", "model/notification")
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end

class NotificationWarning2 < Notification
  
  def name
    tr("This is your second warning for violating the site rules.", "model/notification")
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end

class NotificationWarning3 < Notification
  
  def name
    tr("This is your third warning. You are now on probation.", "model/notification")
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end

class NotificationWarning4 < Notification
  
  def name
    tr("You have been banned for violating the site rules.", "model/notification")
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end
