class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery

  include ApplicationHelper
  include SessionsHelper
  include PostsHelper

  before_filter :get_top_posts

  def expire_post_with_comments(post)
    expire_post(post)
    expire_comments(post)
  end

  def expire_post(post)
    expire_fragment("p#{post.pid}")
    expire_fragment("header@#{page_name}")
    expire_cloud
    expire_sitemap
    begin
      memc_purge(post)
    rescue
    end
  end

  def expire_comments(post)
    expire_fragment("pc#{post.pid}@true")
    expire_fragment("pc#{post.pid}@false")
    begin
      memc_purge(post)
      memc_purge_index
    rescue
    end
  end

  def expire_cloud
    expire_fragment('tagscloud')
    expire_fragment('sitemap')
    expire_fragment('topposts')
  end

  def expire_sitemap
    expire_fragment('sitemap')
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  # fix to handle redirect_to from ajax requests
  def redirect_to(options = {}, response_status = {})
    if request.xhr?
      #render(:update) {|page| page.redirect_to(options)}
      render :inline => "document.location.href = '#{options}'"
    else
      super(options, response_status)
    end
  end

protected

  def get_top_posts
    maxsize = params[:maxsize] || 10
    @top_posts = Post.only(:pid, :title, :comments_counter).
                      where(:created_at.gt => 1.month.ago).
                      desc(:comments_counter).
                      limit(maxsize)
  end
end
