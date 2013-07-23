class AddAnalyticsToSubInstance < ActiveRecord::Migration
  def change
    add_column :sub_instances, :google_analytics_code, :string
  end
end
