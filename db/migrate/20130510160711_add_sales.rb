class AddSales < ActiveRecord::Migration
  def up
    add_column :instances, :sales_email, :string
  end

  def down
  end
end
