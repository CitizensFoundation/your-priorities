class RemoveIPv6Limit < ActiveRecord::Migration
  def up
    change_column :idea_revisions, :ip_address, :string, :limit => 255
    change_column :ideas, :ip_address, :string, :limit => 255
    change_column :revisions, :ip_address, :string, :limit => 255
    change_column :shown_ads, :ip_address, :string, :limit => 255
    change_column :sub_instances, :ip_address, :string, :limit => 255
    change_column :endorsements, :ip_address, :string, :limit => 255
  end

  def down
  end
end
