class AddToDonation < ActiveRecord::Migration
  def up
    add_column :donations, :organisation_name, :string
    add_column :donations, :display_name, :string
    add_column :donations, :anonymous_donor, :boolean, :default=>true
  end

  def down
  end
end
