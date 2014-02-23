class TwitterProfileImage < ActiveRecord::Migration
  def up
    add_column :users, :twitter_profile_image_url, :string
  end

  def down
  end
end
