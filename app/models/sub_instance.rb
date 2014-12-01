class SubInstance < ActiveRecord::Base
  require 'paperclip'
  scope :top10,
        select("sub_instances.id, sub_instances.short_name, sub_instances.iso_country_id, sub_instances.iso_country_id, sub_instances.name, count(ideas.id) AS idea_count").
            joins(:ideas).
            group("sub_instances.id").
            where("sub_instances.iso_country_id IS NOT NULL").
            order("idea_count DESC").
            limit(10)

  scope :active, :conditions => "status in ('pending','active')"
  
  scope :with_logo, :conditions => "logo_file_name is not null"
  
  belongs_to :picture

  has_attached_file :external_link_logo, :styles => { :icon_full => "23x18#",
                                                      :preview => "23x18#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  validates_attachment_size :external_link_logo, :less_than => 5.megabytes
  validates_attachment_content_type :external_link_logo, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  has_attached_file :top_banner, :styles => { :icon_full => "1024x100#",
                                              :preview => "102x10#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  validates_attachment_size :top_banner, :less_than => 5.megabytes
  validates_attachment_content_type :top_banner, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  has_attached_file :menu_strip, :styles => { :icon_full => "5x50#",
                                              :preview => "5x50#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  validates_attachment_size :menu_strip, :less_than => 5.megabytes
  validates_attachment_content_type :menu_strip, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  has_attached_file :menu_strip_side, :styles => { :icon_full => "100x300#",
                                                   :preview => "50x150#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  validates_attachment_size :menu_strip_side, :less_than => 5.megabytes
  validates_attachment_content_type :menu_strip_side, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  has_attached_file :logo, :styles => { :preview => "50x50#", :icon_50 => "50x50#", :icon_full => "200x200#", :icon_96 => "96x96#", :icon_140 => "140x140#", :icon_340_74 => "340x74#", :icon_214_32 => "214x32#", :icon_107_16 => "107x16#", :icon_53_8 => "53x8#", :icon_180 => "180x180#", :medium  => "450x" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
    
  validates_attachment_size :logo, :less_than => 5.megabytes
  validates_attachment_content_type :logo, :content_type => ['image/jpeg', 'image/png', 'image/gif']
  
  has_one :owner, :class_name => "User", :foreign_key => "sub_instance_id"

  has_many :users
  has_many :activities
  has_many :ideas
  has_many :comments

  belongs_to :subscription
  has_many :points
  has_one :iso_country, :class_name => 'IsoCountry'

  include Workflow
  workflow_column :status
  workflow do
    state :passive do
      event :register, transitions_to: :pending
      event :suspend, transitions_to: :suspended
      event :remove, transitions_to: :removed
    end
    state :pending do
      event :activate, transitions_to: :active
      event :suspend, transitions_to: :suspended
      event :remove, transitions_to: :removed
    end
    state :active do
      event :suspend, transitions_to: :suspended
      event :removed, transitions_to: :removed
    end
    state :suspended do
      event :remove, transitions_to: :removed
      event :unsuspend, transitions_to: :active, meta: { validates_presence_of: [:activated_at] }
      event :unsuspend, transitions_to: :pending, meta: { validates_presence_of: [:activation_code] }
      event :unsuspend, transitions_to: :passive
    end
    state :removed
  end

  before_save :clean_urls
  
  #before_validation :shorten_name
  def setup!
    instance = Instance.first
    self.setup_in_progress = false
    self.save!
  end

  belongs_to :iso_country, :class_name => 'IsoCountry', :foreign_key => :iso_country_id

  def logo_url(what_type=:icon_full)
    unless self.logo?
      Instance.current.logo.url(what_type)
    else
      self.logo.url(what_type)
    end
  end

  def external_link_logo_url(what_type=:icon_full)
    if self.external_link_logo.to_s.include?("missing.png")
      Instance.current.external_link_logo.url(what_type)
    else
      self.external_link_logo.url(what_type)
    end
  end

  def top_banner_url(what_type=:icon_full)
    if self.top_banner.to_s.include?("missing.png")
      Instance.current.top_banner.url(what_type)
    else
      self.top_banner.url(what_type)
    end
  end

  def external_link_url(what_type=:icon_full)
    if self.external_link and self.external_link!=""
      self.external_link
    else
      Instance.current.external_link
    end
  end

  def menu_strip_side_url(what_type=:icon_full)
    if self.menu_strip_side.to_s.include?("missing.png")
      Instance.current.menu_strip_side.url(what_type)
    else
      self.menu_strip_side.url(what_type)
    end
  end

  def url(path = '')
    if Rails.env.development? or Rails.env.test?
      if path =~ /\?/
        path = path + "&sub_instance_short_name=#{self.short_name}"
      else
        path = path + "?sub_instance_short_name=#{self.short_name}"
      end
      return '/' + path
    elsif Instance.first.domain_name == "br3.betrireykjavik.is"
      if path =~ /\?/
        path = path + "&sub_instance_short_name=#{self.short_name}"
      else
        path = path + "?sub_instance_short_name=#{self.short_name}"
      end
      'https://' + Instance.first.base_url + '/' + path
    else
      if short_name == "default"
        'https://www.' + Instance.current.base_url + '/' + path
      else
        'https://' + self.short_name + '.' + Instance.current.base_url + '/' + path
      end
    end
  end

  def shorten_name
    self.short_name.gsub(/[^a-z0-9]+/i, '-')
  end
  
  def validate
    if is_optin? and not attribute_present?("optin_text")
      errors.add("optin_text",tr("Please specify the opt-in language if you wish to request their permission to be added to your email list.","here"))
    end
    if is_optin? and optin_text.size > 60
      errors.add("optin_text",tr("needs to be less than 60 characters. Keep it short!","here"))
    end    
    errors.on("optin_text")    
    if is_optin? and not attribute_present?("privacy_url")
      errors.add("privacy_url", tr("Please specify the URL to your privacy policy. This is required if you request the new member's permission to be added to your email list.","here"))
    end
    errors.on("privacy_url")   
    if is_optin? and not attribute_present?("subscribe_url")
      errors.add("subscribe_url", tr("Please specify the URL where people can subscribe to your email list. This is required.","here"))
    end
    errors.on("subscribe_url")
    if is_optin? and not attribute_present?("unsubscribe_url")
      errors.add("unsubscribe_url", tr("Please specify the URL where people can unsubscribe to your email list. This is required.","here"))
    end
    errors.on("unsubscribe_url")       
  end

  validates_uniqueness_of   :short_name, :case_sensitive => false, :message => tr("is already taken.","here")
  validates_length_of       :name, :within => 2..50, :message => tr("should be within 2 and 50 characters.","here")

  ReservedShortnames = %w[admin blog ftp mail pop pop3 imap smtp stage stats status www localize feedback facebook]
  validates_exclusion_of :short_name, :in => ReservedShortnames, :message => tr("is already taken","here")

  def self.current
    if Thread.current[:sub_instance]
      Thread.current[:sub_instance]
    else
      Thread.current[:sub_instance] = SubInstance.first
    end
  end

  def self.current_id
    if Thread.current[:sub_instance]
      Thread.current[:sub_instance].id
    else
      "nosub_instance"
    end
  end

  def self.current=(sub_instance)
    Thread.current[:sub_instance] = sub_instance
  end

  def geoblocking_disabled_for?(country_code)
    self.geoblocking_open_countries.split(',').include?(country_code)
  end

  def clean_urls
    privacy_url = 'http://' + privacy_url if not privacy_url.nil? and privacy_url[0..3] != 'http' 
    unsubscribe_url = 'http://' + unsubscribe_url if not unsubscribe_url.nil? and unsubscribe_url[0..3] != 'http'
    subscribe_url = 'http://' + subscribe_url if not subscribe_url.nil? and subscribe_url[0..3] != 'http'    
  end  
    
  def to_param
    "#{id}-#{short_name.parameterize_full}"
  end

  def on_activated_entry(new_state, event)
    ActivityPartnerNew.create(:user => owner, :sub_instance => self)
  end
  
  def has_picture?
    attribute_present?("picture_id")
  end
  
  def has_logo?
    attribute_present?("logo_file_name")
  end
  
  def has_website?
    attribute_present?("website")
  end  
  
  def website_link
    return nil if self.website.nil?
    wu = website
    wu = 'http://' + wu if wu[0..3] != 'http'
    return wu    
  end
  
  def show_url
    if self.redirect_url
      self.redirect_url
    else
      self.url
    end
  end

  def show_users_url_with_auto_auth(secret)
    self.url("subscription_accounts/users?aa_secret=#{secret}")
  end

  def show_url_with_auto_auth(secret)
    self.url("?aa_secret=#{secret}")
  end

  def custom_tag_dropdown_options(option)
    options = send("custom_tag_dropdown_#{option}")
    out = ""
    options.split(",").each do |o|
      out+="<option>#{o}</option>"
    end
    out
  end
  
  def name_variations
    if self.name_variations_data and self.name_variations_data!=""
      self.name_variations_data.split(",")
    else
      ["missing","missing","missing","missing","missing","missing","missing","missing","missing"]
    end
  end

  def on_removed_entry(new_state, event)
    self.removed_at = Time.now
    save(:validate => false)
  end
end
