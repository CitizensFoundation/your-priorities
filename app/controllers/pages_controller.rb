class PagesController < ApplicationController
  before_filter :authenticate_admin!, :except => [:show]
  #before_filter :authenticate_root!, :except => [:show] #, :if => Proc.new { SubInstance.current.short_name=="default" }

  # GET /pages
  # GET /pages.json
  def index
    @pages = Page.all

    if current_user.is_root?
      @pages = (@pages + Page.unscoped.all).uniq
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
    @page = Page.unscoped.find(params[:id])
    @page_title = @page.title.from_localized_yaml

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.json
  def new
    @page = Page.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @page }
    end
  end

  # GET /pages/1/edit
  def edit
    if current_user.is_root?
      @page = Page.unscoped.find(params[:id])
    else
      @page = Page.find(params[:id])
    end
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = Page.new(params[:page])

    respond_to do |format|
      if @page.save
        format.html { redirect_to @page, notice: tr("Page was successfully created.","here") }
        format.json { render json: @page, status: :created, location: @page }
      else
        format.html { render action: "new" }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update
    if current_user.is_root?
      @page = Page.unscoped.find(params[:id])
    else
      @page = Page.find(params[:id])
    end

    if @page.sub_instance.short_name=="default" and not current_user.is_root?
      redirect_to :back
    end

    respond_to do |format|
      if @page.update_attributes(params[:page])
        format.html { redirect_to @page, notice: 'Page was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy
    @page = Page.find(params[:id])

    if @page.sub_instance.short_name=="default" and not current_user.is_root?
      redirect_to :back
    end

    @page.destroy

    respond_to do |format|
      format.html { redirect_to pages_url }
      format.json { head :no_content }
    end
  end
end
