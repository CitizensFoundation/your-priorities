class ViewedIdea < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"viewed_ideas"

  belongs_to :user
  belongs_to :idea

end
