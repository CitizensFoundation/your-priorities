# This migration comes from monologue (originally 20120526195147)
class AddIndexToPostsRevisionUrl < ActiveRecord::Migration
  def change
    add_index :monologue_posts_revisions, :url
  end
end
