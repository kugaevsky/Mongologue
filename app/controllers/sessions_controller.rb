 class SessionsController < ApplicationController

  def create
    unless params[:token].nil?
      if data = Loginza.user_data(params[:token])
      	# Ok, now we need to add session id to data
        reset_session
        session[:return_to]=params[:return_to]

        user = User.find_or_create_by(:identity => data["identity"])
        # Now we need to create session or something like that
        user.update_attributes(data)
        sign_in(user)
      end
    end
    redirect_back_or root_path
  end

  def destroy
    sign_out
    redirect_back_or root_path
  end

end