class IdeaChart < ActiveRecord::Base
  
  belongs_to :idea
  
  scope :oldest_first, :order => "date_year asc, date_month asc, date_day asc", :limit => 90
  scope :newest_first, :order => "date_year desc, date_month desc, date_day desc", :limit => 90
   
  def date_show
    Time.parse(date_year.to_s + '-' + date_month.to_s + '-' + date_day.to_s).strftime("%b %d")
  end
    
  def IdeaChart.volume(limit=30)
    pc = IdeaChart.find_by_sql(["SELECT date_year, date_month, date_day, sum(idea_charts.volume_count) as volume_count
    from idea_charts
    group by date_year, date_month, date_day
    order by date_year desc, date_month desc, date_day desc
    limit ?",limit])
    pc.collect{|c| c.volume_count.to_i}.reverse
  end
    
end