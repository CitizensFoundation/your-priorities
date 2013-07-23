class AddToIsoCountryDefaultLocale < ActiveRecord::Migration
  def up
    add_column :tr8n_iso_countries, :default_locale, :string, :default=>"en"
  end

  def down
  end
end
