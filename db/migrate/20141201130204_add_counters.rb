class AddCounters < ActiveRecord::Migration
  def up
    add_column :ideas, :counter_endorsements_up, :integer, :default => 0
    add_column :ideas, :counter_endorsements_down, :integer, :default => 0
    add_column :ideas, :counter_points, :integer, :default => 0
    add_column :ideas, :counter_comments, :integer, :default => 0
    add_column :ideas, :counter_all_activities, :integer, :default => 0
    add_column :ideas, :counter_main_activities, :integer, :default => 0

    add_column :sub_instances, :counter_ideas, :integer, :default => 0
    add_column :sub_instances, :counter_points, :integer, :default => 0
    add_column :sub_instances, :counter_users, :integer, :default => 0
    add_column :sub_instances, :counter_comments, :integer, :default => 0
    add_column :sub_instances, :counter_stars, :integer, :default => 0
    add_column :sub_instances, :counter_impressions, :integer, :default => 0
  end

  def down
  end
end
