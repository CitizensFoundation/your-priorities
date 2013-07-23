class AddHttpAuthStuff < ActiveRecord::Migration
  def up
    add_column :sub_instances, :http_auth_username, :string
    add_column :sub_instances, :http_auth_password, :string
  end

  def down
  end
end
