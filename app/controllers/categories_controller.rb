class CategoriesController < ApplicationController
  before_filter :authenticate_admin!, :except=>[:set_filter]

  def set_filter
    if params[:id]=="clear"
      Thread.current[:category_id_filter]=nil
    else
      Thread.current[:category_id_filter]=params[:id]
    end
    session["category_id_filter_#{SubInstance.current.id}"]=Thread.current[:category_id_filter]
    Rails.logger.debug("Setting category id filter to #{params[:id]} #{Thread.current[:category_id_filter]} #{session["category_id_filter_#{SubInstance.current.id}"]}")
    if request.referer
      redirect_to request.referer.split("?")[0]
    else
      redirect_to "/ideas"
    end
  end

  # GET /categories
  # GET /categories.xml
  def index
    if params[:default]
      @categories = Category.unscoped.where("sub_instance_id IS NULL").all
    else
      @categories = Category.all
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  # GET /categories/1
  # GET /categories/1.xml
  def show
    @category = Category.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/new
  # GET /categories/new.xml
  def new
    @category = Category.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.unscoped.find(params[:id])
  end

  # POST /categories
  # POST /categories.xml
  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        format.html { redirect_to(@category, :notice => tr("Category was successfully created.","here")) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.xml
  def update
    @category = Category.unscoped.find(params[:id])

    if @category.sub_instance.short_name=="default" and not current_user.is_root?
      redirect_to :back
    end

    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.html { redirect_to(@category, :notice => 'Category was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.xml
  def destroy
    @category = Category.unscoped.find(params[:id])

    if @category.sub_instance.short_name=="default" and not current_user.is_root?
      redirect_to :back
    end

    @category.destroy

    respond_to do |format|
      format.html { redirect_to(categories_url) }
      format.xml  { head :ok }
    end
  end
end
