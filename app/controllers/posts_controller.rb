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

    items_per_per=50
    if request.format.html?
      items_per_page=10
    end

    # Ok, fulltext search goes here
    if params[:s]
      @posts = Post.my_search(params[:s]).order_by([:created_at, :desc]).\
                    page(params[:page]).per(items_per_page)
    else
      @posts = Post.without(:comments).order_by([:created_at, :desc]).\
                    page(params[:page]).per(items_per_page)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
      format.js
      format.rss  { response.headers["Content-Type"] = "application/xml; charset=utf-8";
                    render :rss => @posts }
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
