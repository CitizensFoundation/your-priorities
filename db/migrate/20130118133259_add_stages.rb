class AddStages < ActiveRecord::Migration
  def up
    add_column :sub_instances, :stage_name, :string, :default=>nil
    add_column :sub_instances, :stage_description, :text, :default=>nil
  end

  def down
  end
end
