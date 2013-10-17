class SendStatusEmail
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(change_log_id)
    Thread.current[:skip_default_scope_globally] = true
    change_log = IdeaStatusChangeLog.find(change_log_id)
    idea = Idea.find(change_log.idea_id)
    User.send_status_email(idea.id, idea.official_status, change_log.date, change_log.subject, change_log.content)
    Thread.current[:skip_default_scope_globally] = nil
  end
end