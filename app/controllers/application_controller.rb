class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include SessionsHelper
  include PostsHelper
  include CommentsHelper
  protect_from_forgery

  filter_parameter_logging :password

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
