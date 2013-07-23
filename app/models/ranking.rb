class Ranking < ActiveRecord::Base
  acts_as_set_sub_instance :table_name=>"rankings"

  belongs_to :idea
    
end
