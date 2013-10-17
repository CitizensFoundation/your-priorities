class AddLocaleToInstance < ActiveRecord::Migration
  def change
    add_column :instances, :default_locale, :string, :default=>"en"
  end
end
