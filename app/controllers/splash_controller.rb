class SplashController < ApplicationController

  def index
    @page_title = tr("Watch what people are doing at {instance_name}", "controller/splash", :instance_name => current_instance.name)
    if User.adapter == 'postgresql'
      @ideas = Idea.find :all, :conditions => "status='published' and position > 0 and endorsements_count > 2", :order => "RANDOM()", :limit => 200
    else
      @ideas = Idea.find :all, :conditions => "status='published' and position > 0 and endorsements_count > 2", :order => "RANDOM()", :limit => 200
    end
  end  
  
end
