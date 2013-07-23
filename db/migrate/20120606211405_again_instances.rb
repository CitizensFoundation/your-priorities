class AgainInstances < ActiveRecord::Migration
  def up
    remove_column :instances, :top_banner
    remove_column :instances, :menu_strip
    remove_column :instances, :menu_strip_side

    add_column :instances, :top_banner_file_name, :string
    add_column :instances, :top_banner_content_type, :string, :limit=>30
    add_column :instances, :top_banner_file_size, :integer
    add_column :instances, :top_banner_updated_at, :datetime

    add_column :instances, :menu_strip_file_name, :string
    add_column :instances, :menu_strip_content_type, :string, :limit=>30
    add_column :instances, :menu_strip_file_size, :integer
    add_column :instances, :menu_strip_updated_at, :datetime

    add_column :instances, :menu_strip_side_file_name, :string
    add_column :instances, :menu_strip_side_content_type, :string, :limit=>30
    add_column :instances, :menu_strip_side_file_size, :integer
    add_column :instances, :menu_strip_side_updated_at, :datetime
  end

  def down
  end
end
