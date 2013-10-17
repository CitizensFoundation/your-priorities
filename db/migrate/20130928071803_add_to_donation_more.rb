class AddToDonationMore < ActiveRecord::Migration
  def up
    add_column :donations, :external_project_id, :integer
  end

  def down
  end
end
