class AddIndexToViewed < ActiveRecord::Migration
  def change
    add_index :viewed_ideas, [:idea_id, :user_id]
    add_index :viewed_ideas, :idea_id
    add_index :viewed_ideas, :user_id
  end
end
