class AddNotes < ActiveRecord::Migration
  def up
    add_column :ideas, :notes, :text
  end

  def down
  end
end
