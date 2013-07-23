class AddFromViewedIdeas < ActiveRecord::Migration
  def up
    create_table "viewed_ideas", :force => true do |t|
      t.integer "idea_id"
      t.integer "user_id"
      t.integer "sub_instance_id"
    end
  end

  def down
  end
end
