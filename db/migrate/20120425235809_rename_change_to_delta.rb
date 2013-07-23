class RenameChangeToDelta < ActiveRecord::Migration
  def change
    %w[1hr 24hr 7days 30days].each do |col|
      rename_column :ideas, "position_#{col}_change", "position_#{col}_delta"
    end
    %w[24hr 7days 30days].each do |col|
      rename_column :users, "position_#{col}_change", "position_#{col}_delta"
      rename_column :users, "index_#{col}_change", "index_#{col}_delta"
    end
  end
end
