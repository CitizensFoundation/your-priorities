class AddAdmins < ActiveRecord::Migration
  def up
    rename_column :users, :is_admin, :is_sub_instance_admin
    add_column :users, :is_root, :boolean, :default=>false
  end

  def down
  end
end