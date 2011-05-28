class PostsController < ApplicationController
  before_filter :authenticate, :only => [:new, :create, :update, :edit, :destroy]
  before_filter :admin_user, :only => [:new, :create, :update, :edit, :destroy]
  before_filter :find_post, :except => [:new, :create, :index]

  def find_post
    @post = Post.where(:pid => params[:id]).first || not_found
  end

  # GET /posts
  # GET /posts.xml
  def index
    # Ok, fulltext search goes here

    if params[:s]
      @posts = Post.my_search(params[:s]).order_by([:created_at, :desc]).page(params[:page]).per(10)
    else
      @posts = Post.without(:comments).order_by([:created_at, :desc]).\
      page(params[:page]).per(10)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
      format.js
    end
  end

  # GET /posts/1
  # GET /posts/1.xml
  def show

    @new_comment = Comment.new

    respond_to do |format|
      format.html  # show.html.erb
      format.xml  { render :xml => @post }
      format.js
    end
  end

  def collapse_comments
    #@post = Post.find(params[:id])
    @new_comment = Comment.new
    respond_to do |format|
      format.js
    end
  end

  def expand_comments
    #@post = Post.find(params[:id])
    @new_comment = Comment.new
    respond_to do |format|
      format.js
    end
  end


  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = Post.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @post }
      format.js
    end
  end

  # GET /posts/1/edit
  def edit
    #@post = Post.find(params[:id])
    respond_to do |format|
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
        expire_post(:id => @post.id)
        format.html { redirect_to(@post, :notice => 'Post was successfully created.') }
        format.xml  { render :xml => @post, :status => :created, :location => @post }
        format.js { render 'create.js.erb' }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.js { render 'shared/error_messages.js.erb', :locals => { :object => @post } }
      end
    end
  end

  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    #@post = Post.find(params[:id])

    respond_to do |format|
      if @post.update_attributes(params[:post])
        expire_cloud
        expire_post(params[:id])
        format.html { redirect_back_or root_path }
        format.xml  { head :ok }
        format.js   { render 'show.js.erb' }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.js   { render 'shared/error_messages.js.erb', :locals => { :object => @post } }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    # @post = Post.find(params[:id])
    @post.destroy
    expire_cloud
    expire_post(:id => @post.id)
    respond_to do |format|
      format.html { redirect_to(posts_url) }
      format.xml  { head :ok }
      format.js { render 'destroy.js.erb' }
    end
  end

  def expire_cloud
    expire_fragment('tagscloud')
  end

  def expire_post(id)
    expire_fragment(:controller => "posts", :action => "index", :id => id)
    expire_fragment(:controller => "posts", :action => "show", :id => id)
  end

end
