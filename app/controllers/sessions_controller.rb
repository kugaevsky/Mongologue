 class SessionsController < ApplicationController

  def create
    unless params[:token].nil?
      if data = Loginza.user_data(params[:token])
        reset_session
        session[:return_to]=params[:return_to]

        user = User.find_or_create_by(:identity => data["identity"])
        # First user to sign in becomes blog admin
        if User.count == 1
          user.admin = true;
        end
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