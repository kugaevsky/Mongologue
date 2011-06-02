class PostsController < ApplicationController
  include ApplicationHelper

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
    @posts = Post.without(:comments)
    @posts = @posts.my_search(params[:s]) if params[:s]
    @posts = @posts.order_by([:created_at, :desc])
    @posts = @posts.where(:pid.lt => params[:p].to_i+1) if params[:p]
    @posts = @posts.limit(items_per_page+1)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
      format.js
      format.rss  { response.headers["Content-Type"] = "application/xml; charset=utf-8";
                    render :rss => @posts }

      format.json { response.headers["Content-Type"] = "application/json; charset=utf-8";
                    render :json => @posts }
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
