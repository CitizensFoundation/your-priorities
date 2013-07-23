class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
       t.text :title
       t.text :content

       t.timestamps
    end

    add_column :sub_instances, :external_link, :string
    add_column :sub_instances, :external_link_logo_file_name, :string
    add_column :sub_instances, :external_link_logo_content_type, :string, :limit=>30
    add_column :sub_instances, :external_link_logo_file_size, :integer
    add_column :sub_instances, :external_link_logo_updated_at, :datetime
  end
end
