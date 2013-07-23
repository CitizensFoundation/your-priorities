class AddGroupIdToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :group_id, :integer
  end
end
