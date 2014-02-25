class UpgradeDeviseInvitable < ActiveRecord::Migration
  def up
    add_column :users, :invitation_created_at, :datetime
  end

  def down
  end
end
