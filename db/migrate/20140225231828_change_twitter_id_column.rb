class ChangeTwitterIdColumn < ActiveRecord::Migration
  def up
    change_column :users, :twitter_id, :bigint
  end

  def down
  end
end
