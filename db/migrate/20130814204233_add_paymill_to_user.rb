class AddPaymillToUser < ActiveRecord::Migration
  def change
    add_column :users, :paymill_id, :string
  end
end
