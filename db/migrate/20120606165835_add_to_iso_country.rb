class AddToIsoCountry < ActiveRecord::Migration
  def up
    add_column :tr8n_iso_countries, :map_coordinates, :text
  end

  def down
  end
end
