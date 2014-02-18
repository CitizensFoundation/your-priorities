class AddConditionsToPages < ActiveRecord::Migration
  def change
    add_column :pages, :hide_from_menu, :boolean, :default=>false
    add_column :pages, :hide_from_menu_unless_admin, :boolean, :default=>false
  end
end
