class AddSubAdmin < ActiveRecord::Migration
  def up
    add_column :users, :is_sub_admin, :boolean, :default=>false
  end

  def down
  end
end