class CalculatePointScore
  include Sidekiq::Worker

  def perform(point_id,action)
    Thread.current[:skip_default_scope_globally] = true
    Point.unscoped.find(point_id).calculate_score(action)
    Thread.current[:skip_default_scope_globally] = nil
  end
end