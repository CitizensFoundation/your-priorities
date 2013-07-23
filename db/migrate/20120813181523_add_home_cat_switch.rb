class AddHomeCatSwitch < ActiveRecord::Migration
  def up
    add_column :sub_instances, :use_category_home_page, :boolean, :default=>false
  end

  def down
  end
end
