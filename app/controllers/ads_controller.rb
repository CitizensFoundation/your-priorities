class AdsController < ApplicationController

  before_filter :get_idea
  before_filter :authenticate_user!, :only => [:new, :create, :preview, :skip]

  before_filter :setup_filter_dropdown

  # GET /ideas/1/ads
  def index
    @ads = @idea.ads.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    @page_title = tr("All ads for {idea_name}", "controller/ads", :idea_name => @idea.name)
    respond_to do |format|
      format.html { redirect_to idea_url(@idea) }
      format.xml { render :xml => @ads.to_xml(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/1/ads/1
  def show
    @ad = @idea.ads.find(params[:id])
    @page_title = tr("Ad for {idea_name}", "controller/ads", :idea_name => @idea.name)
    @activities = @ad.activities.active.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @ad.to_xml(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ad.to_json(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/1/ads/new
  def new
#    if @idea.position < 26
#      flash[:error] = tr("You cannot buy an ad for a idea that's already in the top 25.", "controller/ads")
#      redirect_to @idea
#      return
#    end
    @page_title = tr("Buy an ad for {idea_name}", "controller/ads", :idea_name => @idea.name)
    @ad = @idea.ads.new
    @ad.user = current_user
    @ad.cost = 1
    @ad.show_ads_count = 100
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /ideas/1/ads
  def create
    @ad = @idea.ads.new(params[:ad])
    @ad.user = current_user
    respond_to do |format|
      if @ad.save
        flash[:notice] = tr("Purchased an ad for {idea_name}", "controller/ads", :idea_name => @idea.name)
        format.html { redirect_to(idea_ad_path(@idea,@ad)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def preview
    @ad = @idea.ads.new(params[:ad])
    @ad.user = current_user
    respond_to do |format|    
      format.js {
        render :update do |page|
          page.replace_html 'encouragement_preview', render(:partial => "ads/show", :locals => {:ad => @ad, :endorsement => Endorsement.new})
          page.replace_html 'encouragement_per_user_cost', render(:partial => "ads/per_user_cost", :locals => {:ad => @ad})
          page.replace_html 'encouragement_ranking', render(:partial => "ads/ranking", :locals => {:ad => @ad})
        end
      }
    end
  end
  
  # POST /ideas/1/ads/1/skip
  def skip
    @ad = @idea.ads.find(params[:id])
    @ad.vote(current_user,-2,request)
    @idea.reload
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace 'encouragements', render(:partial => "ads/pick")
        end
      }
    end
  end  
  
  protected
  def get_idea
    @idea = Idea.find(params[:idea_id])
    @endorsement = nil
    if user_signed_in? # pull their endorsement for this idea
      @endorsement = @idea.endorsements.active.find_by_user_id(current_user.id)
    end    
  end

  def setup_menu_items
    @items = Hash.new
    if @idea
      setup_main_ideas_menu
    end
    @items
  end
end
