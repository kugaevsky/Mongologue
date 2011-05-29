class PostsController < ApplicationController
  before_filter :find_post, :except => [:index]

  def find_post
    @post = Post.where(:pid => params[:id]).first || not_found
  end

  # GET /posts
  # GET /posts.xml
  def index
    # We have new post form embedded into index
    @post=Post.new

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
    @new_comment = Comment.new
    respond_to do |format|
      format.js
    end
  end

  def expand_comments
    @new_comment = Comment.new
    respond_to do |format|
      format.js
    end
  end

end
