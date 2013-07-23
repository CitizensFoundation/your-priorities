class AddTimeToStory < ActiveRecord::Migration
  def change
    add_column :ideas, :occurred_at, :string
  end
end
