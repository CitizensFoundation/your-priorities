class AddDescToSubInst < ActiveRecord::Migration
  def change
      add_column :sub_instances, :description, :text
  end
end
