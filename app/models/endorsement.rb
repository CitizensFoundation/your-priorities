class Endorsement < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"endorsements"

  scope :active, :conditions => "endorsements.status = 'active'"
  scope :removed, :conditions => "endorsements.status = 'removed'" 
  scope :suspended, :conditions => "endorsements.status = 'suspended'"
  scope :active_and_inactive, :conditions => "endorsements.status in ('active','inactive','finished')" 
  scope :opposing, :conditions => "endorsements.value < 0"
  scope :endorsing, :conditions => "endorsements.value > 0"
  scope :official_endorsed, :conditions => "ideas.official_value = 1", :include => :idea
  scope :not_official, :conditions => "ideas.official_value = 0", :include => :idea
  scope :official_opposed, :conditions => "ideas.official_value = -1", :include => :idea
  scope :not_official_or_opposed, :conditions => "ideas.official_value < 1", :include => :idea
  scope :finished, :conditions => "endorsements.status in ('inactive','finished') and ideas.status = 'inactive'", :include => :idea
  scope :top10, :order => "endorsements.position asc", :limit => 10
  
  scope :by_position, :order => "endorsements.position asc"
  scope :by_idea_position, :order => "ideas.position asc"
  scope :by_idea_lowest_position, :order => "ideas.position desc"
  scope :by_recently_created, :order => "endorsements.created_at desc"
  scope :by_recently_updated, :order => "endorsements.updated_at desc"  
  
  belongs_to :sub_instance
  belongs_to :user
  belongs_to :idea
  belongs_to :referral, :class_name => "User", :foreign_key => "referral_id"
  
  belongs_to :tagging
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  has_many :top_endorsements, :class_name => "User", :foreign_key => "top_endorsement_id", :dependent => :nullify
  
  cattr_reader :per_page, :max_position
  @@per_page = 25
  @@max_position = 1000000
  
  # docs: http://noobonrails.blogspot.com/2007/02/actsaslist-makes-lists-drop-dead-easy.html
  #acts_as_list :scope => "endorsements.user_id = #{user_id} AND status = 'active'"

  acts_as_list :scope => [:sub_instance_id,:user_id] #:scope => "endorsements.status = 'active'"

  after_create :on_active_entry

  include Workflow
  workflow_column :status
  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
      event :finish, transitions_to: :finished
      event :suspend, transitions_to: :suspended
      event :replace, transitions_to: :replaced
      event :remove, transitions_to: :removed
    end
    state :inactive do
      event :finish, transitions_to: :finished
    end
    state :finished do
      event :deactivate, transitions_to: :inactive
    end
    state :removed do
      event :activate, transitions_to: :active
      event :unremove, transitions_to: :active
      event :replace, transitions_to: :replaced
    end
    state :suspended do
      event :activate, transitions_to: :active
      event :unsuspend, transitions_to: :active
    end
    state :replaced do
      event :activate, transitions_to: :active
      event :unremove, transitions_to: :active
    end
  end

  def on_removed_entry(new_state, event)
#    if user_id == Instance.current.official_user_id and idea.official_value != 0
#      Idea.update_all("official_value = 0", ["id = ?",idea_id])
#    end
    delete_update_counts
    if self.is_up?
      ActivityEndorsementDelete.create(:user => user, :sub_instance => sub_instance, :idea => idea)
    else
      ActivityOppositionDelete.create(:user => user, :sub_instance => sub_instance, :idea => idea)
    end
  end

  def on_finished_entry(new_state, event)
    remove_from_list
    #notifications << NotificationIdeaFinished.new(:recipient => self.user)
  end

  def on_replaced_entry(new_state, event)
    delete_update_counts
  end

  def on_active_entry(new_state = nil, event = nil)
    if self.is_up?
      ActivityEndorsementNew.create(:user => user, :sub_instance => sub_instance, :idea => idea, :position => self.position)
    else
      ActivityOppositionNew.create(:user => user, :sub_instance => sub_instance, :idea => idea, :position => self.position)
    end
    move_to_bottom
    add_update_counts
    save(:validate => false) if persisted?
  end

  def on_suspended_entry(new_state, event)
    delete_update_counts
  end

  before_create :calculate_score
  after_save :check_for_top_idea
  after_save :check_official
  before_destroy :remove!
  after_destroy :check_for_top_idea
  
  # check to see if they've added a new #1 idea, and create the activity
  def check_for_top_idea
    return
    if self.position == 1
      if self.id != user.top_endorsement_id
        user.top_endorsement = self
        user.save(:validate => false)
        if self.is_up?
          ActivityIdea1.find_or_create_by_user_id_and_idea_id(user.id, self.idea_id)
        elsif self.is_down?
          ActivityIdea1Opposed.find_or_create_by_user_id_and_idea_id(user.id, self.idea_id)
        end
      end
    elsif user.top_endorsement_id.nil?
      e = user.endorsements.active.by_position.find(:all, :conditions => "position > 0", :limit => 1)[0]
      user.top_endorsement = e
      user.save(:validate => false)
      if e
        if e.is_up?
          ActivityIdea1.find_or_create_by_user_id_and_idea_id(user.id, e.idea_id)
        elsif e.is_down?
          ActivityIdea1Opposed.find_or_create_by_user_id_and_idea_id(user.id, e.idea_id)
        end      
      end
    end
  end
  
  def check_official
#    return unless user_id == Instance.current.official_user_id
#    Idea.update_all("official_value = 1", ["id = ?",idea_id]) if is_up? and status == 'active'
#    Idea.update_all("official_value = -1", ["id = ?",idea_id]) if is_down? and status == 'active'
#    Idea.update_all("official_value = 0", ["id = ?",idea_id]) if status == 'removed'
  end
  
  def idea_name
    @idea_name ||= idea.name if idea
  end
  
  def idea_name=(n)
    self.idea = Idea.find_by_name(n) unless n.blank?
  end
  
  def calculate_score
    if position > @@max_position  # this ignores any of a user's ideas below 100
      self.score = 0 
    else
      self.score = user.score*value*(@@max_position-position)
    end
  end
  
  #
  #  EXTENDING ACTS_AS_LIST to adjust the score in addition to the position
  #
  
  # Forces item to assume the bottom position in the list.
  def assume_bottom_position
    update_attribute(position_column, bottom_position_in_list(self).to_i + 1)
  end

  # Forces item to assume the top position in the list.
  def assume_top_position
    update_attribute(position_column, 1)
  end  
  
  # This has the effect of moving all the higher items up one.
  def decrement_positions_on_higher_items(position)
    Endorsement.update_all(
      "#{position_column} = (#{position_column} - 1), score = score + value*#{user.score}", "#{scope_condition} AND #{position_column} <= #{position}"
    )
  end

  # This has the effect of moving all the lower items up one.
  def decrement_positions_on_lower_items
    return unless in_list?
    Endorsement.update_all(
      "#{position_column} = (#{position_column} - 1), score = score + value*#{user.score}", "#{scope_condition} AND #{position_column} > #{send(position_column).to_i}"
    )
  end

  # This has the effect of moving all the higher items down one.
  def increment_positions_on_higher_items
    return unless in_list?
    Endorsement.update_all(
      "#{position_column} = (#{position_column} + 1), score = score - value*#{user.score}", "#{scope_condition} AND #{position_column} < #{send(position_column).to_i}")
  end

  # This has the effect of moving all the lower items down one.
  def increment_positions_on_lower_items(position)
    Endorsement.update_all(
      "#{position_column} = (#{position_column} + 1), score = score - value*#{user.score}", "#{scope_condition} AND #{position_column} >= #{position}"
   )
  end

  # Increments position (<tt>position_column</tt>) of all items in the list.
  def increment_positions_on_all_items
    Endorsement.update_all(
      "#{position_column} = (#{position_column} + 1), score = score - value*#{user.score}",  "#{scope_condition}"
    )
  end

  def insert_lowest_at(position)
    self.insert_at([user.endorsements.where(:sub_instance_id=>self.sub_instance_id).count,4].min)
  end
  
  def insert_at_position(position)
    remove_from_list
    increment_positions_on_lower_items(position)
    self.update_attribute(position_column, position)
    self.update_attribute(:score, calculate_score)
  end  
  
  #
  # / EXTENDED ACTS_AS_LIST
  #
  
  def is_up?
    self.value > 0
  end
  
  def is_down?
    not self.is_up?
  end
  
  def is_active?
    status == 'active'
  end

  def is_replaced?
    status == 'replaced'
  end

  def value_name
    return tr("supported", "model/endorsement") if is_up?
    return tr("opposed", "model/endorsement") if is_down?
  end

  def flip_up
    return self if self.is_up?
    self.value = 1
  end
  
  def flip_down
    return self if self.is_down?
    self.value = -1
  end

  def idea
    Idea.unscoped.find(idea_id) if idea_id
  end

  private
  
  def delete_update_counts
#    if self.is_up?
#      Idea.update_all("endorsements_count = endorsements_count - 1, up_endorsements_count = up_endorsements_count - 1", "id = #{self.idea_id}")
#    else
#      Idea.update_all("endorsements_count = endorsements_count - 1, down_endorsements_count = down_endorsements_count - 1", "id = #{self.idea_id}")
#    end
    user.endorsements_count += -1
    if self.is_up?
      user.up_endorsements_count += -1
    else
      user.down_endorsements_count += -1
    end  
    user.save(:validate => false)
    if user.qualities_count > 0 and idea.points_count > 0
      for p in idea.points.published.all
        p.calculate_score(true,self)
      end
    end
  end
  
  def add_update_counts
#    if self.is_up?
#      Idea.update_all("endorsements_count = endorsements_count + 1, up_endorsements_count = up_endorsements_count + 1", "id = #{self.idea_id}")
#    else
#      Idea.update_all("endorsements_count = endorsements_count + 1, down_endorsements_count = down_endorsements_count + 1", "id = #{self.idea_id}")
#    end
    user.endorsements_count += 1
    if self.is_up?
      user.up_endorsements_count += 1
    else
      user.down_endorsements_count += 1
    end  
    user.save(:validate => false) 
    if user.qualities_count > 0 and idea.points_count > 0
      for p in idea.points.published.all
        p.calculate_score(true,self)
      end
    end
  end


end
