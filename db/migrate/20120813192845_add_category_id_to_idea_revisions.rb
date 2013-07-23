class AddCategoryIdToIdeaRevisions < ActiveRecord::Migration
  def change
    add_column :idea_revisions, :category_id, :integer
  end
end
