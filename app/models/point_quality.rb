class PointQuality < ActiveRecord::Base

  belongs_to :user
  belongs_to :point
  
  after_create :add_point_counts
  before_destroy :remove_point_counts
  
  
  #
  #
  #   this doesn't work when it's destroyed because it's a before_destroy method
  #
  #
  
  def add_point_counts
    if self.is_helpful?
      point.helpful_count += 1

      if is_endorser?
        point.endorser_helpful_count += 1
        point.capitals << CapitalPointHelpfulEndorsers.new(:recipient => point.author_user, :amount => 1)
      elsif is_neutral?
        point.neutral_helpful_count += 1
        point.capitals << CapitalPointHelpfulUndeclareds.new(:recipient => point.author_user, :amount => 1)
      elsif is_opposer?
        point.opposer_helpful_count += 1
        point.capitals << CapitalPointHelpfulOpposers.new(:recipient => point.author_user, :amount => 1)
      end

      point.save(:validate => false)

      if point.point_qualities.count > 1
        CalculatePointScore.perform_async(point.id,true)
        #point.delay.calculate_score(true)
      else
        point.calculate_score(true)
      end

      ActivityPointHelpful.create(:point => point, :user => user, :idea => point.idea)
    else
      point.unhelpful_count += 1
      if is_endorser?
        point.endorser_helpful_count -= 1
        # negative point ratings should not cost authors social points
        point.capitals << CapitalPointHelpfulEndorsers.new(:recipient => point.author_user, :amount => -1)
      elsif is_neutral?
        point.neutral_helpful_count -= 1
        point.capitals << CapitalPointHelpfulUndeclareds.new(:recipient => point.author_user, :amount => -1)
      elsif is_opposer?
        point.opposer_helpful_count -= 1
        point.capitals << CapitalPointHelpfulOpposers.new(:recipient => point.author_user, :amount => -1)
      end

      #point.delay.calculate_score(true)
      point.save(:validate => false)
      CalculatePointScore.perform_async(point.id,true)
      ActivityPointUnhelpful.create(:point => point, :user => user, :idea => point.idea)
    end
    user.increment!(:qualities_count)
  end

  def remove_point_counts
    if self.is_helpful?
      point.helpful_count -= 1
      if is_endorser?
        point.endorser_helpful_count -= 1
        point.capitals << CapitalPointHelpfulEndorsers.new(:recipient => point.author_user, :amount => -1, :is_undo => true)
      elsif is_neutral?
        point.neutral_helpful_count -= 1
        point.capitals << CapitalPointHelpfulUndeclareds.new(:recipient => point.author_user, :amount => -1, :is_undo => true)
      elsif is_opposer?
        point.opposer_helpful_count -= 1
        point.capitals << CapitalPointHelpfulOpposers.new(:recipient => point.author_user, :amount => -1, :is_undo => true)
      end
      #point.delay.calculate_score(true)
      point.save(:validate => false)
      CalculatePointScore.perform_async(point.id,true)
      ActivityPointHelpfulDelete.create(:point => point, :user => user, :idea => point.idea)
    else
      point.unhelpful_count -= 1
      if is_endorser?
        point.endorser_helpful_count += 1
        # negative point ratings should not cost authors social points
        #point.capitals << CapitalPointHelpfulEndorsers.new(:recipient => point.author_user, :amount => 1, :is_undo => true)
      elsif is_neutral?
        point.neutral_helpful_count += 1
        #point.capitals << CapitalPointHelpfulUndeclareds.new(:recipient => point.author_user, :amount => 1, :is_undo => true)
      elsif is_opposer?
        point.opposer_helpful_count += 1
        #point.capitals << CapitalPointHelpfulOpposers.new(:recipient => point.author_user, :amount => 1, :is_undo => true)
      end
      #point.delay.calculate_score(true)
      point.save(:validate => false)
      CalculatePointScore.perform_async(point.id,true)
      ActivityPointUnhelpfulDelete.create(:point => point, :user => user, :idea => point.idea)
    end
    user.decrement!(:qualities_count)    
  end
  
  def is_helpful?
    value
  end
  
  def is_unhelpful?
    not value
  end  
  
  def endorsement
    Point.unscoped do
      @endorsement ||= user.endorsements.active_and_inactive.find_by_idea_id(point.idea_id)
    end
    @endorsement
  end
  
  def is_endorser?
    endorsement and endorsement.is_up?
  end
  
  def is_neutral?
    not endorsement
  end
  
  def is_opposer?
    endorsement and endorsement.is_down?
  end
  
end
