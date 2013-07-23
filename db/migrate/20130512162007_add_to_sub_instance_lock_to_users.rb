class AddToSubInstanceLockToUsers < ActiveRecord::Migration
  def change
    add_column :sub_instances, :lock_users_to_instance, :boolean, :default=>false
  end
end
