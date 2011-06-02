class TagsController < ApplicationController

  def index
    # Ok, search goes here
    if params[:term].nil?
      @tags = Tag.without(:value).all
    else
      @tags = Tag.where(:_id => /^#{params[:term].strip}/).without(:value).all
    end
    respond_to do |format|
      format.json { response.headers['Content-Type'] = 'application/json; charset=utf-8';
                    render :inline => "#{@tags.map(&:id).to_json.html_safe}" }
    end
  end

  def show
    if params[:id]=='*'
      @tags = Tag.without(:value).all
    else
      @tags = Tag.where(:_id => /#{params[:id]}/).without(:value).all
    end
    respond_to do |format|
      format.json { response.headers["Content-Type"] = "application/json; charset=utf-8";
                    render :inline => "#{@tags.to_set.map(&:id).flatten.to_json.html_safe}" }
    end
  end

end