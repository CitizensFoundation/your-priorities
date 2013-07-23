class AddFix < ActiveRecord::Migration
  def up
    remove_column :plans, :private
    add_column :plans, :private_instance, :boolean, :default=>false
  end

  def down
  end
end
