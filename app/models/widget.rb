class Widget < ActiveRecord::Base

  belongs_to :user
  belongs_to :tag

  def ideas_available
    a = Array.new
    a << [ "top", tr("Top ideas", "model/widget") ]
    a << [ "rising", tr("Rising ideas", "model/widget") ]
    a << [ "falling", tr("Falling ideas", "model/widget") ]
    a << [ "random", tr("Random ideas", "model/widget") ]
    a << [ "newest", tr("New ideas", "model/widget") ]
    a << [ "controversial", tr("Controversial ideas", "model/widget") ]
    a << [ "finished", tr("Finished ideas", "model/widget") ]
    a
  end

  def discussions_available
    a = Array.new
    if false and user
      a << [ "your_discussions", tr("Your discussions", "model/widget") ]
      a << [ "your_network_discussions", tr("Discussions in your network", "model/widget") ]
      a << [ "your_ideas_discussions", tr("Discussions on your ideas", "model/widget") ]
      a << [ "your_ideas_created_discussions", tr("Discussions on ideas you created", "model/widget") ]
    end
    a << [ "discussions", tr("Active discussions", "model/widget") ]
  end
  
  def points_available
    [
      [ "index", tr("Your points", "model/widget") ],
      [ "your_ideas", tr("Points on your ideas", "model/widget")  ],
      [ "newest", tr("Newest points", "model/widget")  ]
    ]
  end
  
  def charts_available
    [
      [ "charts_idea", tr("Chart Idea", "model/widget") ],
      [ "charts_user", tr("Your ideas", "model/widget") ]
    ]
  end

  def javascript_url
    if self.attribute_present?("tag_id")
      s = 'issues/' + tag.slug + '/' + self.action_name
    else
      s = self.controller_name + "/" + self.action_name
    end
    if self.user
      Instance.current.homepage_url + s + ".js?user_id=" + self.user.id.to_s + "&per_page=" + number.to_s
    else
      Instance.current.homepage_url + s + ".js?per_page=" + number.to_s
    end
  end
  
  def javascript_code
    "<script src='" + javascript_url + "' type='text/javascript'></script>"
  end
  
end
