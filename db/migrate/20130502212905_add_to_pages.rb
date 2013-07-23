class AddToPages < ActiveRecord::Migration
  def up
    add_column :pages, :weight, :integer, :default=>0
    add_column :pages, :sub_instance_id, :integer
  end

  def down
  end
end
