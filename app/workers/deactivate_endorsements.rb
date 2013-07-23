class DeactivateEndorsements
  include Sidekiq::Worker

  def perform(idea_id)
    Idea.unscoped.find(idea_id).deactivate_endorsements
  end
end