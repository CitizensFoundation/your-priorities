class AddViewCounter < ActiveRecord::Migration
  def up
    add_column :ideas, :impressions_count, :integer
  end

  def down
  end
end
