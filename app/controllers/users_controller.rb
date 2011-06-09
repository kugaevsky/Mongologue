class UsersController < ApplicationController
  before_filter :find_user, :only => [:show]

  def find_user
    @user = User.find(params[:id]) || not_found
  end

  def index

    @title = "Users"

    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end


  def show
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def edit


  end

  def update


  end


end
