class AddToPlans < ActiveRecord::Migration
  def up
    remove_column :plans, :price
    add_column :plans, :price_gbp, :float
    add_column :plans, :price_usd, :float
    add_column :plans, :price_eur, :float
    add_column :users, :company, :string
  end

  def down
  end
end
