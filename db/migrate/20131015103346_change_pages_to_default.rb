class ChangePagesToDefault < ActiveRecord::Migration
  def up
    default_id = SubInstance.find_by_short_name("default").id
    Page.unscoped.all.each do |p|
      p.sub_instance_id = default_id
      p.save
    end
  end

  def down
  end
end
