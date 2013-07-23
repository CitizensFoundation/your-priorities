class AddFallBackToInstance < ActiveRecord::Migration
  def change
    add_column :instances, :top_banner, :string
    add_column :instances, :menu_strip, :string
    add_column :instances, :menu_strip_side, :string
  end
end
