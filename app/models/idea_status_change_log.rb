class IdeaStatusChangeLog < ActiveRecord::Base
  belongs_to :idea
  has_many :activities, :dependent => :destroy
end
