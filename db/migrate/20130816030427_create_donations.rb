class CreateDonations < ActiveRecord::Migration
  def change
    create_table :donations do |t|
      t.string :cardholder_name
      t.string :email
      t.string :paymill_client_id
      t.string :paymill_transaction_id
      t.string :currency
      t.float :amount

      t.timestamps
    end
  end
end
