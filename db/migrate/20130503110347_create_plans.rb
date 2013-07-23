class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :paymill_id
      t.text :name
      t.text :description
      t.float :price
      t.string :currency
      t.integer :max_users

      t.timestamps
    end
  end
end
