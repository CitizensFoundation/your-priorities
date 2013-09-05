class ChangePlan < ActiveRecord::Migration
  def up
    remove_column :plans, :price_gbp
    remove_column :plans, :price_eur
    remove_column :plans, :price_usd
    remove_column :plans, :price_isk

    add_column :plans, :amount, :float
    add_column :plans, :vat, :float
    add_column :plans, :paymill_offer_id, :string
  end

  def down
  end
end
