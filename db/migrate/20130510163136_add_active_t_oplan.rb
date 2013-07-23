class AddActiveTOplan < ActiveRecord::Migration
  def up
    add_column :plans, :active, :boolean, :default=>true
  end

  def down
  end
end
