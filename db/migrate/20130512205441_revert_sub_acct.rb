class RevertSubAcct < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.table_exists? 'subscription_accounts'  
      rename_table :subscription_accounts, :accounts
    end
  end

  def down
  end
end
