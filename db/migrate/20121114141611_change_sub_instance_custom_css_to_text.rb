class ChangeSubInstanceCustomCssToText < ActiveRecord::Migration
  def up
    change_column :sub_instances, :custom_css, :text
  end

  def down
  end
end
