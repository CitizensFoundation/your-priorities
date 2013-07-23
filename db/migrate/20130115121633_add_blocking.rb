class AddBlocking < ActiveRecord::Migration
  def up
    add_column :sub_instances, :block_new_ideas, :text, :default=>nil
    add_column :sub_instances, :block_points, :text, :default=>nil
    add_column :sub_instances, :block_comments, :text, :default=>nil
    add_column :sub_instances, :block_endorsements, :text, :default=>nil
  end

  def down
  end
end
