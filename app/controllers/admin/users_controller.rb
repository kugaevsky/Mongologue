class Admin::UsersController < ApplicationController
  before_filter :authenticate
  before_filter :find_user
  before_filter :correct_user

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
      if params[:user][:password].empty?
        @user.remove_password
        format.js { render 'admin/users/update', :locals => { :user => @user } }
      elsif @user.update_attributes(params[:user])
        # format.html { redirect_back_or root_path }
        format.xml  { head :ok }
        format.js { render 'admin/users/update', :locals => { :user => @user } }
      else
        # format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.js   { render 'shared/error_messages.js.erb', :locals => { :object => @user } }
      end
    end
  end

  def correct_user
#   @user = User.find(params[:id])
    redirect_to(root_path) unless (current_user?(@user) or current_user.admin?)
  end


end
