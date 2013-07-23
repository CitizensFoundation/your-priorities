class ChangeSubInstanceAdminToAdmin < ActiveRecord::Migration
  def up
    rename_column :users, :is_sub_instance_admin, :is_admin
  end

  def down
  end
end
