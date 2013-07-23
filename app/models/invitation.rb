class Invitation < ActiveRecord::Base
  
  scope :has_sender, :conditions => "sender_id is not null"
  
  belongs_to :user
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :sub_instance
  belongs_to :recipient, :class_name => "User", :foreign_key => "to_id"

  has_many :activities
  include Workflow
  workflow_column :status
  workflow do
    state :unsent do
      event :send, transitions_to: :sent
      event :accept, transitions_to: :accepted
    end
    state :sent do
      event :accept, transitions_to: :accepted
    end
    state :accepted
  end

  validates_presence_of     :to_email, :unless => :has_facebook?
  validates_presence_of     :from_name
  #validates_presence_of    :to_name
  validates_length_of       :from_name,    :minimum => 3
  validates_length_of       :to_email,    :minimum => 3
  validates_format_of       :to_email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x
  
  def has_facebook?
    attribute_present?("facebook_uid")
  end
  
end
