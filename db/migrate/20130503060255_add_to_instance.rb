class AddToInstance < ActiveRecord::Migration
  def up
    add_column :instances, :external_link_logo_file_name, :string
    add_column :instances, :external_link_logo_content_type, :string, :limit=>30
    add_column :instances, :external_link_logo_file_size, :integer
    add_column :instances, :external_link_logo_updated_at, :datetime
  end

  def down
  end
end
