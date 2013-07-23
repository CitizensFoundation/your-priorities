class AddDisableEmailLogin < ActiveRecord::Migration
  def up
    add_column :instances, :disable_email_login, :boolean, :default=>false
  end

  def down
  end
end
