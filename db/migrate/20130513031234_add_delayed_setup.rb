class AddDelayedSetup < ActiveRecord::Migration
  def up
    add_column :sub_instances, :setup_in_progress, :boolean, :default=>false
  end

  def down
  end
end
