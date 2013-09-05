class AddToSubInstanceOrgType < ActiveRecord::Migration
  def up
   add_column :sub_instances, :map_coordinates, :string
   add_column :sub_instances, :organization_type, :string
   add_column :sub_instances, :redirect_url, :string
   change_column :sub_instances, :map_coordinates, :text

  end

  def down
  end
end
