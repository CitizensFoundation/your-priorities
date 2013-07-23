class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :paymill_id
      t.integer :user_id
      t.integer :plan_id
      t.datetime :last_payment_at
      t.boolean :active

      t.timestamps
    end
  end
end
