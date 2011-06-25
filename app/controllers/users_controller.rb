class UsersController < ApplicationController

  def clientinfo
    respond_to do |format|
      format.html { render :partial => 'clientinfo' }
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
