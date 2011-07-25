class UserMailer < ActionMailer::Base
  default from: "blog@daekrist.net"

  def new_post_email(user,post)
    @user = user
    @post = post
    mail(:to => user.email,
         :subject => "New post: '#{post.title}'")
  end


  def new_comment_email(user,post,comment)
    @user = user
    @post = post
    @comment = comment
    mail(:to => user.email,
         :subject => "#{comment.name} commented '#{post.title}'")
  end

  def new_reply_email(user,post,comment)
    @user = user
    @post = post
    @comment = comment
    @reply = comment.reply
    @reply_name = comment.reply_name
    mail(:to => user.email,
         :subject => "#{comment.reply_name} replied for '#{post.title}'")

  end


end
