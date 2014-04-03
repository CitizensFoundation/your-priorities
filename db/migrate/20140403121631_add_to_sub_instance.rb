class AddToSubInstance < ActiveRecord::Migration
  def up
    add_column :sub_instances, :ask_for_post_code, :boolean, :default=>false
  end

  def down
  end
end
