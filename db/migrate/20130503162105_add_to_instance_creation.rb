class AddToInstanceCreation < ActiveRecord::Migration
  def up
    add_column :sub_instances, :subscription_enabled, :boolean, :default=>false
    add_column :plans, :private, :boolean, :default=>false
  end

  def down
  end
end
