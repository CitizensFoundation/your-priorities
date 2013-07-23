# This migration comes from monologue (originally 20120604010152)
class RenamePostTagsTable < ActiveRecord::Migration
  def change
    rename_table :posts_tags, :monologue_posts_tags
  end
end
