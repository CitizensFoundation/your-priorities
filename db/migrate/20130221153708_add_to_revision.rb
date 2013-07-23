class AddToRevision < ActiveRecord::Migration
  def up
    add_column :idea_revisions, :notes_diff, :text 
  end

  def down
  end
end
