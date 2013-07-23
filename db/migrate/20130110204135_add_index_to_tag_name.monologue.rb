# This migration comes from monologue (originally 20120612020023)
class AddIndexToTagName < ActiveRecord::Migration
  def change
    add_index :monologue_tags, :name
  end
end
