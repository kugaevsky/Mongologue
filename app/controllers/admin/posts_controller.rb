class Admin::PostsController < ApplicationController
  before_filter :authenticate
  before_filter :admin_user
  before_filter :find_post, :except => [:new, :create, :index]


  def find_post
    @post = Post.where(:pid => params[:id]).first || not_found
  end

  # GET /posts/new
  # GET /posts/new.xml
  def new
    # @post = Post.new

    respond_to do |format|
      # format.html # new.html.erb
      # format.xml  { render :xml => @post }
      # format.js
    end
  end


  def edit

    respond_to do |format|
      format.html
      format.js
    end
  end

  # POST /posts
  # POST /posts.xml
  def create
    @post = Post.new(params[:post])

    respond_to do |format|
      if @post.save
        expire_cloud
        expire_post(@post)
        # format.html { redirect_to(@post, :notice => 'Post was successfully created.') }
        format.xml  { render :xml => @post, :status => :created, :location => @post }
        format.js { render 'create.js.erb' }
      else
        # format.html { render :action => "new" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.js { render 'shared/error_messages.js.erb', :locals => { :object => @post } }
      end
    end
  end


  # PUT /admin/posts/1
  # PUT /admin/posts/1.xml
  def update

    respond_to do |format|
      if @post.update_attributes(params[:post])
        expire_cloud
        expire_post(@post)
        # format.html { redirect_back_or root_path }
        format.xml  { head :ok }
        format.js   { render 'posts/show.js.erb' }
      else
        # format.html { render :action => "edit" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.js   { render 'shared/error_messages.js.erb', :locals => { :object => @post } }
      end
    end
  end

  # DELETE /admin/posts/1
  # DELETE /admin/posts/1.xml
  def destroy
    @post.destroy
    expire_cloud
    expire_post(@post)
    respond_to do |format|
      # format.html { redirect_to(posts_url) }
      format.xml  { head :ok }
      format.js { render 'destroy.js.erb' }
    end
  end


end
