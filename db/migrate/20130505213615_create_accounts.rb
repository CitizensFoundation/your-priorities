class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :subscription_accounts do |t|
      t.string :name
      t.string :paymill_id
      t.integer :user_id
      t.boolean :active

      t.timestamps
    end

    add_column :users, :account_id, :integer
    add_column :plans, :price_isk, :float
    remove_column :plans, :paymill_id
    add_column :subscriptions, :account_id, :integer
    add_column :sub_instances, :subscription_id, :integer
  end
end
