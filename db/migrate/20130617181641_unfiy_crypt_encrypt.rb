class UnfiyCryptEncrypt < ActiveRecord::Migration
  def up
    if User.last.respond_to?(:old_encrypted_password)
      rename_column :users, :old_encrypted_password, :old_crypted_password
    end
  end

  def down
  end
end
