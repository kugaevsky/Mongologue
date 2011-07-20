class UsersController < ApplicationController
before_filter :authenticate, :only => [:index, :show]
before_filter :admin_user, :only => [:index,:show]

  def clientinfo
    respond_to do |format|
      format.html { render 'clientinfo', :layout => false }
      format.js
    end
  end


  def index

    @title = "Users"
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
    end
  end


  def show
    @user = User.find(params[:id]) || not_found
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def edit


  end

  def update


  end


end
