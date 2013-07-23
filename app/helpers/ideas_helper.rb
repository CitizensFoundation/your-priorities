module IdeasHelper

  def get_points_number_text(points_count, total_points,new_points=false)
    if points_count>0
      "(#{points_count} #{tr("of","points")} #{total_points})".html_safe
    else
      "(#{new_points ? tr("no new points", "helper/ideas") : tr("no points", "helper/ideas")})".html_safe
    end
  end
end