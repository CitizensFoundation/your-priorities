class LastLocale < ActiveRecord::Migration
  def up
    add_column :users, :last_locale, :string
  end

  def down
  end
end
