class AddToPage < ActiveRecord::Migration
  def up
    add_column :pages, :name, :string
    add_index :pages, :name
  end

  def down
  end
end
