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

end
