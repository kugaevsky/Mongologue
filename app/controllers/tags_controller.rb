class TagsController < ApplicationController
  # caches_action :index

  def index
    @tags = Tag.only(:_id)
    @tags = if !params[:term]
      @tags.all
    else
      @tags = @tags.where(:_id => /^#{params[:term].strip}/).all
    end
    tags_ids = @tags.map(&:_id)

    respond_to do |format|
      format.html { render :partial => 'tagscloud' }
      format.json { render json: tags_ids }
      format.xml  { render xml:  tags_ids }
      format.text { render text: tags_ids.join('|') }
    end
  end

  def show
    @tags = Tag.without(:value)
    @tags = if params[:id]=='*'
      @tags.all
    else
      @tags.where(:_id => /#{params[:id]}/).all
    end
    respond_to do |format|
      format.json { render json: @tags.map(&:_id) }
      format.xml  { render xml:  @tags }
    end
  end
end
