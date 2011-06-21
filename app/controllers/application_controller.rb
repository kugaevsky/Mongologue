class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include ApplicationHelper
  include SessionsHelper
  include PostsHelper
  include CommentsHelper
  protect_from_forgery

  def expire_post_with_comments(post)
    expire_post(post)
    expire_comments(post)
  end

  def expire_post(post)
    expire_fragment("p#{post.pid}@true")
    expire_fragment("p#{post.pid}@false")
    expire_fragment("youarehere@p#{post.pid}")
    expire_fragment("header@#{page_name}")
    expire_sitemap
  end

  def expire_comments(post)
    expire_fragment("pc#{post.pid}@true")
    expire_fragment("pc#{post.pid}@false")
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
      render(:update) {|page| page.redirect_to(options)}
    else
      super(options, response_status)
    end
  end

end
