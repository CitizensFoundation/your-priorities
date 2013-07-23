class AddRevisionsForIdeas < ActiveRecord::Migration
  def up
    create_table "idea_revisions", :force => true do |t|
      t.integer  "idea_id"
      t.integer  "user_id"
      t.string   "status",        :limit => 50
      t.string   "name",          :limit => 60
      t.text     "description"
      t.datetime "published_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "ip_address",    :limit => 16
      t.string   "user_agent",    :limit => 150
      t.text     "name_diff"
      t.text     "description_diff"
      t.integer  "other_idea_id"
      t.text     "description_html"
    end
    add_column :ideas, :idea_revision_id, :integer
    add_column :ideas, :author_sentence, :string
    add_column :activities, :idea_revision_id, :integer
    add_column :ideas, :idea_revisions_count, :integer, default: 0
    add_column :users, :idea_revisions_count, :integer, default: 0
    add_column :users, :is_idea_changes_subscribed, :boolean, default: false
    add_column :unsubscribes, :is_idea_changes_subscribed, :boolean, default: false

    IdeaRevision.reset_column_information
    Idea.reset_column_information
    User.reset_column_information
    Activity.reset_column_information

    Idea.transaction do
      Idea.unscoped.all.each do |idea|
        idea.setup_revision
      end
    end
  end

  def down
  end
end
