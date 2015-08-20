class AddCustomInviteMessage < ActiveRecord::Migration
  def up
    add_column :sub_instances, :custom_invite_email_text, :text, :default=>nil
  end

  def down
  end
end
