class Group < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"groups"

  has_and_belongs_to_many :users

  before_destroy { users.clear }

  def self.set_admin_for_group(user, group)
    users_group = GroupsUser.find_or_create(:user_id=>user.id, :group_id=>group.id)
    users_group.is_admin = true
    users_group.save
  end
end
