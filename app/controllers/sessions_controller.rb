 class SessionsController < ApplicationController



  def new
    unless params[:token].nil?
      if data = Loginza.user_data(params[:token])
        reset_session
        session[:return_to]=params[:return_to]

        user = User.find_or_create_by(:identity => data["identity"])
        # First user to sign in becomes blog admin
        if User.count == 1
          @user.admin = true;
        end

        if user.encrypted_password.nil?
          user.update_attributes(data)
          sign_in(user)
          redirect_to root_path
        else
          session[:data]=data
          render 'new'
        end
      else
        redirect_to root_path
      end
    else
      redirect_to root_path
    end
  end

  def create
    user = User.authenticate(session[:data]['identity'],
                             params[:session][:password])
    if user.nil?
      flash.now[:error] = "Wrong password."
      render "new"
    else
      user.update_attributes(session[:data])
      sign_in user
      session[:data]=''
      redirect_to root_path
    end
  end



  def destroy
    sign_out
    redirect_back_or root_path
  end

end