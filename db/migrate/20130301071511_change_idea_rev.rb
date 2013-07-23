class ChangeIdeaRev < ActiveRecord::Migration
  def up
    change_column :ideas, :name, :string, :limit => 250
    change_column :idea_revisions, :name, :string, :limit => 250
  end

  def down
  end
end
