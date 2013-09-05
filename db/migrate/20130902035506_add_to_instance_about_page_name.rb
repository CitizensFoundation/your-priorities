class AddToInstanceAboutPageName < ActiveRecord::Migration
  def up
    add_column :instances, :about_page_name, :string
  end

  def down
  end
end
