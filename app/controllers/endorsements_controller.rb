class EndorsementsController < ApplicationController
 
  before_filter :authenticate_user!, :except => :index
  
  # GET /endorsements
  # GET /endorsements.xml
  def index
    @endorsements = Endorsement.active_and_inactive.by_recently_created(:include => [:user,:idea]).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { redirect_to yours_ideas_url }
      format.xml { render :xml => @endorsements.to_xml(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def edit
    @endorsement = current_user.endorsements.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'idea_left'
            page.replace_html 'idea_' + @endorsement.idea.id.to_s + '_position', render(:partial => "endorsements/position_form", :locals => {:endorsement => @endorsement})
            page['endorsement_' + @endorsement.id.to_s + "_position_edit"].focus
          elsif params[:region] == 'yours'
            page.replace_html 'endorsement_' + @endorsement.id.to_s, render(:partial => "endorsements/row_form", :locals => {:endorsement => @endorsement})
            page['endorsement_' + @endorsement.id.to_s + "_row_edit"].focus
          end
        end        
      }
    end
  end
  
  def update
    @endorsement = current_user.endorsements.find(params[:id])
    return if params[:endorsement][:position].to_i < 1  # if they didn't put a number in, don't do anything
    if @endorsement.insert_at(params[:endorsement][:position]) 
      respond_to do |format|
        format.js {
          render :update do |page|
            if params[:region] == 'idea_left'
              page.replace_html 'idea_' + @endorsement.idea.id.to_s + "_position",render(:partial => "endorsements/position", :locals => {:endorsement => @endorsement})
            elsif params[:region] == 'yours'
            end
            #page.replace_html 'your_ideas_container', :partial => "ideas/yours"
          end
        }
      end
    end
  end
  
  # DELETE /endorsements/1
  def destroy
    if current_user.is_admin?
      @endorsement = Endorsement.find(params[:id])
    else
      @endorsement = current_user.endorsements.find(params[:id])
    end
    return unless @endorsement
    Idea.unscoped {
      @idea = @endorsement.idea
    }
    eid = @endorsement.id
    @endorsement.destroy
    Idea.unscoped {
      @idea.reload
    }
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'idea_left'
            page.replace_html 'idea_' + @idea.id.to_s + "_button",render(:partial => "ideas/debate_buttons", :locals => {:force_debate_to_new=>(params[:force_debate_to_new] and params[:force_debate_to_new].to_i==1) ? true : false, :idea => @idea, :endorsement => nil, :region=>"idea_left"})
            page.replace_html 'idea_' + @idea.id.to_s + "_position",render(:partial => "endorsements/position", :locals => {:endorsement => nil})
            page.replace 'endorser_link', render(:partial => "ideas/endorser_link")
            page.replace 'opposer_link', render(:partial => "ideas/opposer_link")
            if @endorsement.is_up?
              @activity = ActivityEndorsementDelete.find_by_idea_id_and_user_id(@idea.id,current_user.id, :order => "created_at desc")
            else
              @activity = ActivityOppositionDelete.find_by_idea_id_and_user_id(@idea.id,current_user.id, :order => "created_at desc")
            end          
            page.insert_html :top, 'activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => "_noself"})
          elsif params[:region] == 'idea_subs'
            page.replace_html 'idea_' + @idea.id.to_s + "_button",render(:partial => "ideas/button_subs", :locals => {:idea => @idea, :endorsement => nil})
            page.replace 'endorser_link', render(:partial => "ideas/endorser_link")
            page.replace 'opposer_link', render(:partial => "ideas/opposer_link")
          elsif ['idea_inline'].include?(params[:region])
            page<<"$('.idea_#{@idea.id.to_s}_button_small').replaceWith('#{escape_javascript(render(:partial => "ideas/debate_buttons", :locals => {:force_debate_to_new=>(params[:force_debate_to_new] and params[:force_debate_to_new].to_i==1) ? true : false, :idea => @idea, :endorsement => nil, :region => params[:region]}))}')"
            page<<"$('.idea_#{@idea.id.to_s}_endorsement_count').replaceWith('#{escape_javascript(render(:partial => "ideas/endorsement_count", :locals => {:idea => @idea}))}')"
          elsif params[:region] == 'your_ideas'
            # page.visual_effect :fade, 'endorsement_' + eid.to_s, :duration => 0.5
          elsif params[:region] == 'ad'
          end     
          #page.replace_html 'your_ideas_container', :partial => "ideas/yours"
          # page.visual_effect :highlight, 'your_ideas' unless params[:region] == 'your_ideas'
        end
      }    
    end
  end

end
