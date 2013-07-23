class AddWeightToTolk < ActiveRecord::Migration
  def change
    add_column :tolk_locales, :weight, :integer, :default=>1000
  end
end
