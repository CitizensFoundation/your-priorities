class OneMoreForDeviseUpgrade < ActiveRecord::Migration
  def up
    add_column :users, :invitations_count, :integer, :default => 0

    add_index :users, :invitations_count  
end

  def down
  end
end
