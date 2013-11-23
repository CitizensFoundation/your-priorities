class Instance < ActiveRecord::Base
  require 'paperclip'
  
  scope :active, :conditions => "status = 'active'"
  scope :pending, :conditions => "status = 'pending'"
  scope :least_active, :conditions => "status = 'active'", :order => "users_count"
  scope :facebook, :conditions => "is_facebook = true"
  scope :twitter, :conditions => "is_twitter = true"
  
  belongs_to :official_user, :class_name => "User"
  belongs_to :color_scheme
  
  belongs_to :picture

  has_attached_file :external_link_logo, :styles => { :icon_full => "23x18#",
                                                      :preview => "23x18#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  validates_attachment_size :external_link_logo, :less_than => 5.megabytes
  validates_attachment_content_type :external_link_logo, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  has_attached_file :favicon, :styles => { :icon_full => "16x16" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  validates_attachment_content_type :favicon, :content_type => ['image/x-icon', 'image/vnd.microsoft.icon']

  has_attached_file :top_banner, :styles => { :icon_full => "1024x100#",
                                              :preview => "102x10#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  validates_attachment_size :top_banner, :less_than => 5.megabytes
  validates_attachment_content_type :top_banner, :content_type => ['image/jpeg', 'image/jpg','image/png', 'image/gif']

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

  has_attached_file :logo, :styles => { :icon_full => "200x200#", :preview => "50x50#", :icon_50 => "50x50#", :icon_96 => "96x96#", :icon_140 => "140x140#", :icon_340_74 => "340x74#", :icon_214_32 => "214x32#", :icon_107_16 => "107x16#", :icon_53_8 => "53x8#", :icon_180 => "180x180#", :medium  => "450x" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS

  validates_attachment_size :logo, :less_than => 5.megabytes
  validates_attachment_content_type :logo, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  has_attached_file :email_banner,
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS

  validates_attachment_size :email_banner, :less_than => 5.megabytes
  validates_attachment_content_type :email_banner, :content_type => ['image/jpeg', 'image/png', 'image/gif']
    
  belongs_to :buddy_icon_old, :class_name => "Picture"
  has_attached_file :buddy_icon, :styles => { :icon_24 => "24x24#", :icon_48  => "48x48#", :icon_50 => "50x50#", :icon_96 => "96x96#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
    
  validates_attachment_size :buddy_icon, :less_than => 5.megabytes
  validates_attachment_content_type :buddy_icon, :content_type => ['image/jpeg', 'image/png', 'image/gif']    
      
  belongs_to :fav_icon_old, :class_name => "Picture"
  has_attached_file :fav_icon, :styles => { :icon_16 => "16x16#" },
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS
  
  validates_attachment_size :fav_icon, :less_than => 5.megabytes
  validates_attachment_content_type :fav_icon, :content_type => ['image/jpeg', 'image/png', 'image/gif']  
  
  validates_presence_of     :name
  validates_length_of       :name, :within => 3..60

  validates_presence_of     :admin_name
  validates_length_of       :admin_name, :within => 3..60

  validates_presence_of     :admin_email
  validates_length_of       :admin_email, :within => 3..100, :allow_nil => true, :allow_blank => true
  validates_format_of       :admin_email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x

#  validates_presence_of     :email
#  validates_length_of       :email, :within => 3..100, :allow_nil => true, :allow_blank => true
#  validates_format_of       :email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x

  validates_presence_of     :tags_name
  validates_length_of       :tags_name, :maximum => 20
  validates_presence_of     :currency_name
  validates_length_of       :currency_name, :maximum => 30
  validates_presence_of     :currency_short_name
  validates_length_of       :currency_short_name, :maximum => 3
  
  after_save :clear_cache
  before_save :last_minute_checks
  
  def last_minute_checks
    self.homepage = 'top' if not self.is_tags? and self.homepage == 'index'
  end

  def clear_cache
    Rails.cache.delete('instance')
    return true
  end
  
  def self.current
    if Thread.current[:instance]
      Thread.current[:instance]
    else
      Thread.current[:instance]=Instance.last
    end
  end
  
  def self.current=(instance)
    raise(ArgumentError,"Invalid instance. Expected an object of class 'Instance', got #{instance.inspect}") unless instance.is_a?(Instance)
    Thread.current[:instance] = instance
  end
  
  def base_url
    self.domain_name
  end

  def base_url_w_sub_instance
    if SubInstance.current
      SubInstance.current.short_name + '.' + self.domain_name
    else
      self.domain_name
    end
  end
  
  def homepage_url(sub_instance=nil)
    if Thread.current[:localhost_override]
      'https://' + Thread.current[:localhost_override] + '/'
    else
      if (p = sub_instance || (p = SubInstance.current)) && p.short_name != "default"
        'https://' + p.short_name + '.' + base_url + '/'
      elsif (p = sub_instance || (p = SubInstance.current)) && p.short_name == "default"
        'https://www.' + base_url + '/'
      else
        'https://' + base_url + '/'
      end
    end
  end

  def homepage_top_url
    'https://www.' + base_url + '/'
  end

  def name_with_tagline
    return name unless attribute_present?("tagline")
    name + ": " + tagline
  end
  
  def update_counts
    self.users_count = User.count
    self.ideas_count = Idea.published.count
    self.endorsements_count = Endorsement.active_and_inactive.count
    self.sub_instances_count = SubInstance.active.count
    self.points_count = Point.published.count
    self.contributors_count = User.active.at_least_one_endorsement.contributed.count
    self.save(:validate => false)
  end  
  
  def has_official?
    false
    #attribute_present?("official_user_id")
  end

  def official_user_name
    official_user.name if official_user
  end
  
  def official_user_name=(n)
    self.official_user = User.find_by_login(n) unless n.blank?
  end  
  
  def has_google_analytics?
    attribute_present?("google_analytics_code")
  end
  
  def has_twitter_enabled?
    return false unless is_twitter?
    return true if attribute_present?("twitter_key") and attribute_present?("twitter_secret_key")
  end
  
  def has_facebook_enabled?
    return false unless is_facebook?
    return true
  end
  
  def has_windows_enabled?
    self.attribute_present?("windows_appid")
  end
  
  def has_yahoo_enabled?
    self.attribute_present?("yahoo_appid")
  end
  
  # this will go away when full migrated to paperclip
  def has_picture?
    attribute_present?("picture_id")
  end
  
  def has_email_banner?
    attribute_present?("email_banner_file_name")
  end

  def has_fav_icon?
    attribute_present?("fav_icon_file_name")
  end
  
  def has_buddy_icon?
    attribute_present?("buddy_icon_file_name")
  end
  
  def has_logo?
    attribute_present?("logo_file_name")
  end
  
  def is_searchable?
    not ENV["WEBSOLR_URL"].nil?
  end

  def logo_large
    return nil unless has_logo?
    '<div class="logo_small"><a href="/"><img src="' + logo.url(:medium) + '" border="0"></a></div>'
  end  
  
  def logo_small
    return nil unless has_logo?
    '<div class="logo_small"><a href="/"><img src="' + logo.url(:icon_140) + '" border="0"></a></div>'
  end
  
  def tags_name_plural
    tags_name.pluralize
  end

end
