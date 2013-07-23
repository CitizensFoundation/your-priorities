class AddAttachmentEmailBannerToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :email_banner_file_name, :string
    add_column :instances, :email_banner_content_type, :string
    add_column :instances, :email_banner_file_size, :integer
    add_column :instances, :email_banner_updated_at, :datetime
  end

  def self.down
    remove_column :instances, :email_banner_file_name
    remove_column :instances, :email_banner_content_type
    remove_column :instances, :email_banner_file_size
    remove_column :instances, :email_banner_updated_at
  end
end
