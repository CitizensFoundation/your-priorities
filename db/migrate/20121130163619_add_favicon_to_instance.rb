class AddFaviconToInstance < ActiveRecord::Migration
  def change
    change_table(:instances) do |t|
      t.column :favicon_file_name, :string
      t.column :favicon_content_type, :string, limit: 30
      t.column :favicon_file_size, :integer
      t.column :favicon_updated_at, :datetime
    end
  end
end
