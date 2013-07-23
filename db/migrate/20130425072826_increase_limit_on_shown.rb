class IncreaseLimitOnShown < ActiveRecord::Migration
  def up
    change_column :shown_ads, :user_agent, :string, :limit=>1000
    change_column :shown_ads, :referrer, :string, :limit=>1000
  end

  def down
  end
end
