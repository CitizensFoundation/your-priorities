# This migration comes from monologue (originally 20120114001001)
class CreateMonologueUsers < ActiveRecord::Migration
  def change
    create_table :monologue_users do |t|
      t.string :name
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
