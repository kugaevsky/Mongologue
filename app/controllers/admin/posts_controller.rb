class Admin::PostsController < ApplicationController
  include ApplicationHelper
  include PostsHelper
  before_filter :authenticate
  before_filter :admin_user
  before_filter :find_post, :except => [:new, :create, :index]

  def items_per_page
    if request.format.html? or request.format.js?
      return 15
    else
      return 20
    end
  end

  def find_post
    @post = Post.where(:pid => params[:id]).first || not_found
  end

  # GET /posts
  # GET /posts.xml
  def index
    start_post = Post.where(:pid => params[:p]).first || not_found if params[:p]

    # We have new post form embedded into index
    @post=Post.new

    # Ok, fulltext search goes here
    @posts = Post.without(:comments)
    @posts = @posts.my_search(params[:s]) if params[:s]
    @posts = @posts.order_by([:created_at, :desc])
    @posts = @posts.where(:created_at.lte => start_post.created_at) if params[:p]
    @posts_count = @posts.count
    @posts = @posts.limit(items_per_page+1).to_ary

    @next_page_pid = @posts.size!= items_per_page+1 ? nil : @posts.last.pid

    @title = @posts.first.title if @posts.size!=0

    respond_to do |format|
      format.html { expires_in 0.seconds, :public => false if signed_in?;

                   }
      format.js

      format.json { response.headers["Content-Type"] = "application/json; charset=utf-8";
                    expires_in 0.seconds, :public => false;
                    render :json => @posts }
    end
  end


  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = Post.new

    respond_to do |format|
      format.html # new.html.erb
      # format.xml  { render :xml => @post }
      # format.js
    end
  end


  def edit

    @post.remove_autotags!
    respond_to do |format|
      format.html
      format.js
    end
  end

  # POST /posts
  # POST /posts.xml
  def create
    @post = Post.new(params[:post])
    @post.created_at = Time.now

    respond_to do |format|
      if @post.save
        expire_cloud
        format.html { redirect_to(@post, :notice => 'Post was successfully created.') }
        # format.xml  { render :xml => @post, :status => :created, :location => @post }
        format.js { render 'create.js.erb' }
      else
        format.html { render :action => "new" }
        # format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
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
        format.html { redirect_back_or root_path }
        # format.xml  { head :ok }
        format.js   { render 'posts/show.js.erb' }
      else
        format.html { render :action => "edit" }
        # format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.js   { render 'shared/error_messages.js.erb', :locals => { :object => @post } }
      end
    end
  end

  # DELETE /admin/posts/1
  # DELETE /admin/posts/1.xml
  def destroy
    @post.destroy
    expire_cloud
    expire_post_with_comments(@post)
    expire_action :action => :index
    respond_to do |format|
      # format.html { redirect_to(posts_url) }
      format.xml  { head :ok }
      format.js { render 'destroy.js.erb' }
    end
  end


end
