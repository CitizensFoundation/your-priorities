class RenameDeletedAtToRemovedAt < ActiveRecord::Migration
  def change
    [:notifications, :sub_instances, :ideas, :users].each do |table|
      rename_column table, :deleted_at, :removed_at
    end
  end
end
