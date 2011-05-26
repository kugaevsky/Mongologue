class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include SessionsHelper
  protect_from_forgery
end
