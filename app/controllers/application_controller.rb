class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include SessionsHelper
  protect_from_forgery

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

end
