class Admin::CommentsController < ApplicationController
  include ApplicationHelper

  before_filter :authenticate
  before_filter :admin_user

  before_filter :find_post
  before_filter :find_comment, :except => [:create]

  def find_post
    @post = Post.where(:pid => params[:post_id]).first || not_found
  end

  def find_comment
    @comment = @post.comments.where(:pid => params[:id]).first || not_found
  end

  # Handles only replies
  def edit
    @comment.reply = unprepare_text(@comment.reply) unless @comment.reply.nil?
    # @comment.content = unprepare_text(@comment.content)
    respond_to do |format|
      format.js { render 'edit_reply.js.erb' }
      format.html { render 'edit_reply.html.erb' }
    end
  end

  def destroy
    @comment.destroy
    expire_comments(@post)
    respond_to do |format|
      format.html { redirect_to @post }
      format.xml  { head :ok }
      format.js { render 'destroy_comment.js.erb' }
    end
  end

  # Handles only replies
  def update
    @new_comment = Comment.new

    respond_to do |format|

      @comment.reply = params[:comment][:reply]
      if @comment.reply.empty?
        @comment.reply = nil
        @comment.reply_name = nil
        @comment.reply_url = nil
      else
        @comment.reply_name = identity_or_name(current_user)
        @comment.reply_url = current_user.identity
      end
      if @comment.save
        expire_comments(@post)
        format.html { redirect_to( @post, :notice => "Reply updated.") }
        # format.xml  { head :ok }
        format.js   { render 'comments/show_reply.js.erb' }
      else
        format.html { render :template => 'posts/show' }
        # format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.js   { render 'shared/error_messages.js.erb', :locals => { :object => @comment } }
      end
    end
  end

end
