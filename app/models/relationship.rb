class Relationship < ActiveRecord::Base

  scope :who_endorsed, :conditions => "relationships.type in ('RelationshipEndorserEndorsed','RelationshipOpposerEndorsed','RelationshipUndecidedEndorsed')"
  scope :endorsers_endorsed, :conditions => "relationships.type = 'RelationshipEndorserEndorsed'"
  scope :opposers_endorsed, :conditions => "relationships.type = 'RelationshipOpposerEndorsed'"
  scope :undecideds_endorsed, :conditions => "relationships.type = 'RelationshipUndecidedEndorsed'"    
  scope :by_highest_percentage, :order => "relationships.percentage desc"

  belongs_to :idea
  belongs_to :other_idea, :class_name => "Idea"
  
  after_create :add_counts
  before_destroy :remove_counts
  
  def add_counts
    idea = Idea.find(self.idea_id)
    idea.update_attribute("relationships_count", idea.relationships_count + 1)
  end
  
  def remove_counts
    idea = Idea.find(self.idea_id)
    idea.update_attribute("relationships_count", idea.relationships_count - 1)
  end
  
end

class RelationshipEndorserEndorsed < Relationship
  
end

class RelationshipOpposerEndorsed < Relationship
  
end

class RelationshipUndecidedEndorsed < Relationship
  
end
