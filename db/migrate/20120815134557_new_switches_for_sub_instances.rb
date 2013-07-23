class NewSwitchesForSubInstances < ActiveRecord::Migration
  def up
    add_column :sub_instances, :hide_description, :boolean, :default=>false
    add_column :sub_instances, :hide_world_icon, :boolean, :default=>false
    add_column :sub_instances, :idea_name_max_length, :integer, :default=>60
  end

  def down
  end
end
