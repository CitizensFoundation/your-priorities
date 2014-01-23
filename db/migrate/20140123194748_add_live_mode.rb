class AddLiveMode < ActiveRecord::Migration
  def up
    add_column :sub_instances, :use_live_home_page, :boolean, :default=>false
    add_column :sub_instances, :live_stream_id, :string
  end

  def down
  end
end
