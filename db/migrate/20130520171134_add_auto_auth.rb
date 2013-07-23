class AddAutoAuth < ActiveRecord::Migration
  def up
    create_table :auto_authentications do |t|
      t.string :secret
      t.boolean :active, :default=>true
      t.integer :user_id
      t.timestamps
    end

    add_index :auto_authentications, :secret
  end

  def down
  end
end
