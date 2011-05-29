class Admin::UsersController < ApplicationController
  before_filter :authenticate
#  before_filter :admin_user
  before_filter :find_user, :except => ["password_check"]

  def find_user
    @user = User.find(params[:id]) || not_found
  end

  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  # PUT /admin/posts/1
  # PUT /admin/posts/1.xml
  def update

    respond_to do |format|
      if @user.update_attributes(params[:user])
        # format.html { redirect_back_or root_path }
        format.xml  { head :ok }
        format.js   { render :inline => "$('#edituser').slideUp();" }
      else
        # format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.js   { render 'shared/error_messages.js.erb', :locals => { :object => @user } }
      end
    end
  end

end
