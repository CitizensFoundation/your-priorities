class AddToNotification < ActiveRecord::Migration
  def up
    add_column :notifications, :custom_text, :text
  end

  def down
  end
end
