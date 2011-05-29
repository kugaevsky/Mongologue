#encoding: utf-8
class CommentsController < ApplicationController
  before_filter :find_post
  before_filter :find_comment, :except => [:create]

  def find_post
    @post = Post.where(:pid => params[:post_id]).first || not_found
  end

  def find_comment
    @comment = @post.comments.where(:pid => params[:id]).first || not_found
  end

  def create
    @new_comment = @post.comments.build(params[:comment])
    if signed_in?
      @new_comment.name = identity_or_name(current_user)
      @new_comment.url = current_user.identity
    else
      @new_comment.name = "Anonymous"
    end

    @new_comment.ip = request.remote_ip

    respond_to do |format|
      if @new_comment.save
        @post.inc(:comments_counter, 1)
        expire_post(params[:post_id])

        format.html { redirect_to @post }
        format.js   { render 'create_comment.js.erb'   }
      else
        format.html { render :template => 'posts/show' }
        format.js   { render 'shared/error_messages.js.erb', :locals => { :object => @new_comment } }
      end
    end

  end

  def show
    respond_to do |format|
      format.js { render 'show_reply.js.erb' }
      format.html {render :inline => 'COMMENTS' }
    end
  end

end
