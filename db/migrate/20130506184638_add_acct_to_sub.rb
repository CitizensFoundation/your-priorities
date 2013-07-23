class AddAcctToSub < ActiveRecord::Migration
  def change
    add_column :sub_instances, :account_id, :integer
  end
end
