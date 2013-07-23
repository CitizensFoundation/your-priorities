class AddToU < ActiveRecord::Migration
  def up
    add_column :users, :has_accepted_eula, :boolean, :default=>false
  end

  def down
  end
end
