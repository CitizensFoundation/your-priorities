class AddToActivityCustomText < ActiveRecord::Migration
  def up
    add_column :activities, :custom_text, :text
  end

  def down
  end
end
