class AddSsn < ActiveRecord::Migration
  def up
    add_column :users, :ssn, :string
  end

  def down
  end
end
