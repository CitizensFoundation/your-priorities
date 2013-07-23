class AddBannerLinks < ActiveRecord::Migration
  def up
    add_column :sub_instances, :left_link_url, :string
    add_column :sub_instances, :right_link_url, :string
    add_column :sub_instances, :left_link_position, :integer, default: 0
    add_column :sub_instances, :left_link_width, :integer, default: 400
    add_column :sub_instances, :right_link_position, :integer, default: 900
    add_column :sub_instances, :right_link_width, :integer, default: 120
  end

  def down
  end
end
