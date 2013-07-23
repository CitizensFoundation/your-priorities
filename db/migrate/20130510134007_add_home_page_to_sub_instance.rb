class AddHomePageToSubInstance < ActiveRecord::Migration
  def change
    add_column :sub_instances, :home_page_partial, :string, :default=>"index"
    add_column :sub_instances, :home_page_layout, :string, :default=>"application"
    add_column :instances, :layout_for_subscriptions, :string, :default=>"application"
  end
end
