class AddSubLinkHeader < ActiveRecord::Migration
  def up
    add_column :sub_instances, :sub_link_header, :text
  end

  def down
  end
end
