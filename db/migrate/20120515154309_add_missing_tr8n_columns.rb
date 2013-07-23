class AddMissingTr8nColumns < ActiveRecord::Migration
  def up
    add_column :tr8n_translators, :remote_id, :integer
    add_column :tr8n_translation_keys, :synced_at, :datetime
    add_column :tr8n_translations, :synced_at, :datetime
  end

  def down
  end
end
