#encoding: utf-8
class PostsController < ApplicationController
  include ApplicationHelper
  include SessionsHelper

  before_filter :store_location
  before_filter :find_post, :except => [:index, :sitemap]
  
  def find_post
    @post = Post.where(:pid => params[:id]).first || not_found
  end

  def items_per_page
    if request.format.html? or request.format.js?
      return 15
    else
      return 20
    end
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
      format.html { render :html => @posts;
                    memc_write
                   }
      format.js
      format.rss  { response.headers["Content-Type"] = "application/xml; charset=utf-8"
                    render :rss => @posts
                    memc_write }

      format.json { response.headers["Content-Type"] = "application/json; charset=utf-8"
                    render :json => @posts
                    memc_write }
    end
  end

  # GET /posts/1
  # GET /posts/1.xml
  def show

    @title = @post.title

    @new_comment = Comment.new

    respond_to do |format|
      format.html { render :html => @post;
                    memc_write
                  }

      format.xml
      format.js
    end
  end

  def collapse_comments
    @new_comment = Comment.new
    respond_to do |format|
      format.js
      format.html { redirect_to @post }
    end
  end

  def expand_comments
    @new_comment = Comment.new
    respond_to do |format|
      format.js
      format.html { redirect_to @post }
    end
  end

  def sitemap
    @posts=Post.order_by([:created_at, :desc]).only(:pid).all
    @tags=Tag.order_by([:value, :desc]).all
    respond_to do |format|
      format.xml  { response.headers["Content-Type"] = "application/xml; charset=utf-8";
                    render 'sitemap';
                    memc_write(3600)
                  }
    end
  end

end
