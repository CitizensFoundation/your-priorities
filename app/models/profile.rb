class Profile < ActiveRecord::Base

  belongs_to :user

  validates_length_of :bio, :maximum => 500

  auto_html_for(:bio) do
    html_escape
    youtube(:width => 460, :height => 285)
    vimeo(:width => 460, :height => 260)
    link :target => "_blank", :rel => "nofollow"
  end

end
