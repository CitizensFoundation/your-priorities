class AddSamlId < ActiveRecord::Migration
  def up
    add_column :sub_instances, :saml_id, :string
    add_index :sub_instances, :saml_id
  end

  def down
  end
end
