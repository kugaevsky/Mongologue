class UserMailer < ActionMailer::Base
  default to: "daekrist@gmail.com"

  def new_post_email(emails,post)
    @post = post
    mail(:bcc => emails.split(","),
         :subject => "New post: '#{post.title}'")
  end


  def new_comment_email(emails,post,comment)
    @post = post
    @comment = comment
    mail(:bcc => emails.split(","),
         :subject => "#{comment.name} commented '#{post.title}'")
  end

  def new_reply_email(emails,post,comment)
    @post = post
    @comment = comment
    @reply = comment.reply
    @reply_name = comment.reply_name
    mail(:bcc => emails.split(","),
         :subject => "#{comment.reply_name} replied for '#{post.title}'")

  end


end
