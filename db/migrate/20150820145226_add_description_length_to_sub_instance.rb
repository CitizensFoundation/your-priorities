class AddDescriptionLengthToSubInstance < ActiveRecord::Migration
  def change
    add_column :sub_instances, :idea_description_max_length, :integer, :default=>500
  end
end
