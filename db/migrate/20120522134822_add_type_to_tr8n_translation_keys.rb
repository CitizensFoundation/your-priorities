class AddTypeToTr8nTranslationKeys < ActiveRecord::Migration
  def change
    add_column :tr8n_translation_keys, :type, :string
  end
end
