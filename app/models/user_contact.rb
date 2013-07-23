class UserContact < ActiveRecord::Base

  scope :active, :conditions => "user_contacts.status <> 'removed'"
  scope :tosend, :conditions => "user_contacts.status = 'tosend'"  

  scope :members, :include => :user, :conditions => "user_contacts.other_user_id is not null and users.status in ('active','pending')"
  scope :not_members, :conditions => "user_contacts.other_user_id is null"

  scope :invited, :conditions => "user_contacts.sent_at is not null or user_contacts.status = 'tosend'"
  scope :not_invited, :conditions => "user_contacts.sent_at is null and user_contacts.status <> 'tosend'"

  scope :following, :conditions => "user_contacts.following_id is not null"
  scope :not_following, :conditions => "user_contacts.following_id is null"

  scope :facebook, :conditions => "user_contacts.facebook_uid is not null"
  scope :not_facebook, :conditions => "user_contacts.facebook_uid is null"
  
  scope :with_email, :conditions => "user_contacts.email is not null"
  
  scope :recently_updated, :order => "user_contacts.updated_at desc"
  scope :recently_created, :order => "user_contacts.created_at desc"  
  
  belongs_to :user
  belongs_to :other_user, :class_name => "User"
  belongs_to :following

  include Workflow
  workflow_column :status
  workflow do
    state :unsent do
      event :invite, transitions_to: :tosend
      event :accept, transitions_to: :accepted
      event :remove, transitions_to: :removed
    end
    state :tosend do
      event :send, transitions_to: :sent
      event :accept, transitions_to: :accepted
      event :remove, transitions_to: :removed
    end
    state :sent do
      event :accept, transitions_to: :accepted
      event :remove, transitions_to: :removed
    end
    state :accepted do
      event :remove, transitions_to: :removed
    end
    state :removed
  end
  
  validates_presence_of     :email, :unless => :has_facebook?
  validates_length_of       :email, :minimum => 3, :unless => :has_facebook?
  validates_format_of       :email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x, :allow_nil => true, :allow_blank => true

  after_create :add_counts
  before_destroy :remove_counts
  
  def self.import_google(token,user_id)
    uri = URI.parse("https://www.google.com")
    http = Net::HTTP.new(uri.host, uri.port)
    cert = File.read(Rails.root.join("config/yrprirsacert.pem"))
    pem = File.read(Rails.root.join("config/yrprirsakey.pem"))
    http.use_ssl = true 
    http.cert = OpenSSL::X509::Certificate.new(cert) 
    http.key = OpenSSL::PKey::RSA.new(pem) 
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER 
    path = "/m8/feeds/contacts/default/full?max-results=10000"
    headers = {'Authorization' => "AuthSub token=#{token}", 'GData-Version' => "3.0"}
    resp, data = http.get(path, headers)

    @user = User.where(:id=>user_id).first
    offset = 0
    if not @user.is_importing_contacts? or not @user.attribute_present?("imported_contacts_count") or @user.imported_contacts_count > 0
      @user.is_importing_contacts = true
      @user.imported_contacts_count = 0
      @user.save(:validate => false)
    end

    xml = REXML::Document.new(data)
    contacts = []
    xml.elements.each('//entry') do |entry|
      begin
        name = entry.elements['title'].text
        gd_email = entry.elements['gd:email']
        if gd_email
          email = gd_email.attributes['address']
          contact = @user.contacts.find_by_email(email)
          contact = @user.contacts.new unless contact
          contact.name = name
          contact.email = email
          contact.other_user = User.find_by_email(contact.email)
          if @user.followings_count > 0 and contact.other_user
            contact.following = followings.find_by_other_user_id(contact.other_user_id)
          end
          contact.save(:validate => false)          
          offset += 1
          @user.update_attribute(:imported_contacts_count,offset) if offset % 20 == 0
        end
      rescue
        next
      end
    end
    @user.calculate_contacts_count
    @user.imported_contacts_count = offset
    @user.is_importing_contacts = false
    @user.google_crawled_at = Time.now    
    @user.save(:validate => false)
  end

  def add_counts
    return if attribute_present?("following_id") # already in the followings_count
    if attribute_present?("other_user_id")
      user.increment!(:contacts_members_count)
    elsif not is_invited?
      user.increment!(:contacts_not_invited_count)
    elsif is_invited?
      user.increment!(:contacts_invited_count)
    end
    user.increment!(:contacts_count)
  end
  
  def remove_counts
    return if attribute_present?("following_id") # already in the followings_count
    if attribute_present?("other_user_id")
      user.decrement!(:contacts_members_count)
    elsif not is_invited?
      user.decrement!(:contacts_not_invited_count)
    elsif is_invited?
      user.decrement!(:contacts_invited_count)
    end
    user.decrement!(:contacts_count)
  end
  
  cattr_reader :per_page
  @@per_page = 25  
  
  def from_name
    if is_from_realname?
      return user.real_name
    else
      return user.login
    end
  end
  
  def has_facebook?
    attribute_present?("facebook_uid")
  end
  
  def has_email?
    attribute_present?("email")
  end  
  
  def is_sent?
    attribute_present?("sent_at")
  end  
  
  def is_invited?
    status == 'tosend' or attribute_present?("sent_at")
  end
  
  def is_accepted?
    attribute_present?("accepted_at")
  end  
  
  def on_tosend_entry(new_state, event)
    # disabling invitation activity
    #ActivityInvitationNew.create(:user => user)
    user.contacts_invited_count += 1
    user.contacts_not_invited_count += -1
    user.save(:validate => false)
    self.delay.send!
  end
  
  def on_sent_entry(new_state, event)
    return if attribute_present?("sent_at") # only send it once
    send_email
  end

  def send_email
    if has_email?
      UserMailer.invitation(user,from_name,name,email).deliver
    elsif has_facebook?
      # don't do anything on send if it's facebook, because it was sent through the facebook system already
    end    
    self.sent_at = Time.now    
  end
  
  def on_accepted_entry(new_state, event)
    # can deliver an email notifying the person who invited them
    self.accepted_at = Time.now
    if has_email?
      self.other_user = User.find_by_email(email)
    elsif has_facebook?
      self.other_user = User.find_by_facebook_uid(facebook_uid)
    end
    if self.other_user.referral_id != self.user_id
      self.other_user.update_attribute(:referral_id,self.user_id)
      ActivityInvitationAccepted.create(:other_user => user, :user => self.other_user)
      ActivityUserRecruited.create(:user => user, :other_user => self.other_user, :is_user_only => true) 
      user.increment!(:referrals_count)
    end
    self.following = user.follow(self.other_user)
    user.decrement!(:contacts_invited_count)    
    self.other_user.notifications << NotificationInvitationAccepted.new(:sender => self.other_user, :recipient => user)
    save(:validate => false)
  end  
  
  def on_removed_entry(new_state, event)
    remove_counts
  end
  
end
