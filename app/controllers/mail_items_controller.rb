class MailItemsController < ApplicationController
  # GET /mail_items
  # GET /mail_items.xml
  def index
    @mail_items = MailItem.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mail_items }
    end
  end

  # GET /mail_items/1
  # GET /mail_items/1.xml
  def show
    @mail_item = MailItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mail_item }
    end
  end

  # GET /mail_items/new
  # GET /mail_items/new.xml
  def new
    @mail_item = MailItem.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mail_item }
    end
  end

  # GET /mail_items/1/edit
  def edit
    @mail_item = MailItem.find(params[:id])
  end

  # POST /mail_items
  # POST /mail_items.xml
  def create
    @mail_item = MailItem.new(params[:mail_item])

    respond_to do |format|
      if @mail_item.save
        flash[:notice] = 'MailItem was successfully created.'
        format.html { redirect_to(@mail_item) }
        format.xml  { render :xml => @mail_item, :status => :created, :location => @mail_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mail_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /mail_items/1
  # PUT /mail_items/1.xml
  def update
    @mail_item = MailItem.find(params[:id])

    respond_to do |format|
      if @mail_item.update_attributes(params[:mail_item])
        flash[:notice] = 'MailItem was successfully updated.'
        format.html { redirect_to(@mail_item) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mail_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mail_items/1
  # DELETE /mail_items/1.xml
  def destroy
    @mail_item = MailItem.find(params[:id])
    @mail_item.destroy

    respond_to do |format|
      format.html { redirect_to(mail_items_url) }
      format.xml  { head :ok }
    end
  end
end
