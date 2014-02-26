class RemoveLimitsOnUserAgents < ActiveRecord::Migration
  def up
    change_column :users, :user_agent, :string, :limit => nil
    change_column :points, :user_agent, :string, :limit => nil
    change_column :revisions, :user_agent, :string, :limit => nil
    change_column :shown_ads, :user_agent, :string, :limit => nil
    change_column :idea_revisions, :user_agent, :string, :limit => nil
    change_column :ideas, :user_agent, :string, :limit => nil
  end

  def down
  end
end
