class FixUpDefaultUsers < ActiveRecord::Migration
  def up
    User.unscoped.all.each do |user|
      user.sub_instance_id = SubInstance.first.id
      user.save(:validate=>false)
    end
  end

  def down
  end
end
