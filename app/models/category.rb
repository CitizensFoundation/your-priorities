class Category < ActiveRecord::Base
  has_many :ideas
  has_many :blog_posts

  has_attached_file :icon, :styles => { :icon_32 => "32x32#", :icon_200 => "200x200#", :icon_25 => "25x25#",
                                        :icon_40  => "40x40#", :icon_50  => "50x50#", :icon_100 => "100x100#",
                                        :icon_200 => "200x200#"},
                    :storage => PAPERCLIP_STORAGE_MECHANISM,
                    :s3_credentials => S3_CREDENTIALS

  validates_attachment_size :icon, :less_than => 5.megabytes
  validates_attachment_content_type :icon, :content_type => ['image/png']

  acts_as_set_sub_instance :table_name=>"categories"

  def self.default_or_sub_instance
    if Category.count>0
      Category.all
    else
      Category.unscoped.where(:sub_instance_id=>1).all
    end
  end


  def i18n_name
    self.name #tr(self.name, "model/category")
  end
  
  def to_url
    "/issues/#{id}-#{self.name.parameterize_full[0..60]}"
  end

  def show_url
    to_url
  end

  def idea_ids
    ideas.published.collect{|p| p.id}
  end

  def points_count
    Point.published.count(:conditions => ["idea_id in (?)",idea_ids])
  end

  def discussions_count
    Activity.active.discussions.for_all_users.by_recently_updated.count(:conditions => ["idea_id in (?)",idea_ids])
  end
  
  def self.for_sub_instance
    if SubInstance.current and Category.where(:sub_instance_id=>SubInstance.current.id).count > 0
      Category.where(:sub_instance_id=>SubInstance.current.id).order("name")
    else
      Category.where(:sub_instance_id=>nil).order("name")
    end
  end
end
