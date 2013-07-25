 class SessionsController < ApplicationController

  def new
    render 'new'
  end

  def authorize
    @session = params[:session]
    unless params[:token].nil?
      if data = Loginza.user_data(params[:token])
        session[:return_to] = params[:rt]
        # render :inline => "<%= 1+2 %>"
        user = User.find_or_create_by(:dentity => data["identity"])
        # First user to sign in becomes blog admin
        if User.count == 1
          user.admin = true;
          user.save
        end

        if user.encrypted_password.nil?
          user.update_attributes(data)
          sign_in(user)
        else
          session[:data]=data
          respond_to do |format|
            expires_in 0.seconds, :public => false;

            format.js { render 'authorize', :locals => {:user => user} }
            format.html
          end
          return
        end
      end
    end
    redirect_back_or root_path
  end

  def create
    user = User.authenticate(session[:data]['identity'],
                             params[:session][:password])
    respond_to do |format|
    if user.nil?
#     flash.now[:error] = "Wrong password."
      format.js  { render 'authorize.js.erb', :locals => {:user => user} }
      format.html { render 'authorize.html.erb' }
    else
      user.update_attributes(session[:data])
      sign_in user
      session[:data]=''
      expires_in 0.seconds, :public => false;
      format.js  { redirect_back_or root_path }
      format.html { redirect_back_or root_path }
    end
    end
  end

  def destroy
    sign_out
    redirect_back_or root_path
  end

end