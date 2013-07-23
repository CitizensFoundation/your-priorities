class AddToInstanceNew < ActiveRecord::Migration
  def up
    add_column :instances, :external_link, :string
  end

  def down
  end
end
