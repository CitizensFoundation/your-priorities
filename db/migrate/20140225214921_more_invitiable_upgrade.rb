class MoreInvitiableUpgrade < ActiveRecord::Migration
  def up
    change_column :users, :invitation_token, :string, :limit => nil
  end

  def down
  end
end
