class SendCapitalEmail
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(activity_id, point_difference)
    Thread.current[:skip_default_scope_globally] = true
    #User.send_capital_email(activity_id, point_difference)
    Thread.current[:skip_default_scope_globally] = nil
  end
end