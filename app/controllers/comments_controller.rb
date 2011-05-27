#encoding: utf-8
class CommentsController < ApplicationController
  before_filter :authenticate, :except => [:create, :show]
  before_filter :admin_user, :except => [:create, :show]
  before_filter :find_post
  before_filter :find_comment, :except => [:create]

  def find_post
    @post = Post.where(:pid => params[:post_id]).first || not_found
  end

  def find_comment
    @comment = @post.comments.where(:pid => params[:id]).first || not_found
  end

  def create
    # @post = Post.find(params[:post_id])
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
    # @post = Post.find(params[:post_id])
    # @comment = @post.comments.find(params[:id])
    respond_to do |format|
      format.js { render 'show_reply.js.erb' }
    end
  end

  def edit
    # @post = Post.find(params[:post_id])
    # @comment = @post.comments.find(params[:id])
    respond_to do |format|
      format.js { render 'edit_reply.js.erb' }
      format.html { render 'edit_reply.html.erb' }
    end
  end

  def destroy
    # @post = Post.find(params[:post_id])
    # @comment = @post.comments.find(params[:id])
    @comment.destroy
    @post.inc(:comments_counter, -1)
    expire_post(:id => @post.id)
    respond_to do |format|
      format.html { redirect_to @post }
      format.xml  { head :ok }
      format.js { render 'destroy_comment.js.erb' }
    end
  end

  def update
    # @post = Post.find(params[:post_id])
    # @comment = @post.comments.find(params[:id])
    @new_comment = Comment.new

    respond_to do |format|

      @comment.reply = params[:comment][:reply]
      if @comment.reply == ''
        @comment.reply = nil
        @comment.reply_name = nil
        @comment.reply_url = nil
      else
        @comment.reply_name = identity_or_name(current_user)
        @comment.reply_url = current_user.identity
      end
      if @comment.save
        expire_post(params[:post_id])
        format.html { redirect_to( @post, :notice => "Reply updated.") }
        format.xml  { head :ok }
        format.js   { render 'show_reply.js.erb' }
      else
        format.html { render :template => 'posts/show' }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  def expire_post(id)
    expire_fragment(:controller => "posts", :action => "index", :id => id)
    expire_fragment(:controller => "posts", :action => "show", :id => id)
  end
end
