class TagsController < ApplicationController

  def index
    # Ok, search goes here
    if params[:term].nil?
      @tags = Tag.without(:value).all
    else
      @tags = Tag.where(:_id => /^#{params[:term].strip}/).without(:value).all
    end

    # tagcloud = Mongoid.master.collection('tagcloud')
    # @tags = tagcloud.find({}).to_set

    respond_to do |format|
      format.json { response.headers['Content-Type'] = 'application/json; charset=utf-8';
                    render :inline => "#{@tags.map(&:id).to_json.html_safe}" }
      format.xml  { response.headers["Content-Type"] = "application/xml; charset=utf-8";
                    render :inline => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> '+
                                      "<listdata>#{@tags.map(&:id).join('|')}</listdata>" };
      format.text { render :inline => "#{@tags.map(&:id).join('|')}" };
      # "#{@tags.map {|t| t['_id']}.join('|')}" };

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
      format.xml { response.headers["Content-Type"] = "application/xml; charset=utf-8";
                    render :xml => @tags }
    end
  end

end