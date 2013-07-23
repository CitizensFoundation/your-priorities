class AddCustomCss < ActiveRecord::Migration
  def up
    add_column :sub_instances, :custom_css, :string, :default=>nil
  end

  def down
  end
end
