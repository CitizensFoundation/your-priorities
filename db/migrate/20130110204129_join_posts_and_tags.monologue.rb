# This migration comes from monologue (originally 20120514194459)
class JoinPostsAndTags < ActiveRecord::Migration
  def change
     create_table :posts_tags, :id=>false do |t|
       t.integer :post_id,:tag_id
     end
   end
end
