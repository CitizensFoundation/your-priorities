class CalculatePointScore
  include Sidekiq::Worker

  def perform(point_id,action)
    Point.unscoped.find(point_id).calculate_score(action)
  end
end