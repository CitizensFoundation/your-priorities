class AddNotesToRevision < ActiveRecord::Migration
  def change
    add_column :idea_revisions, :notes, :text
  end
end
