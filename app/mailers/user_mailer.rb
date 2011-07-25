class UserMailer < ActionMailer::Base
  default from: 'Daekrist.Net Blog <blog@daekrist.net>'

  def new_post_email(emails,post)
    @post = post
    mail(:to => emails.split(","),
         :subject => "New post: '#{post.title}'")
  end


  def new_comment_email(emails,post,comment)
    @post = post
    @comment = comment
    mail(:to => emails.split(","),
         :subject => "#{comment.name} commented '#{post.title}'")
  end

  def new_reply_email(emails,post,comment)
    @post = post
    @comment = comment
    @reply = comment.reply
    @reply_name = comment.reply_name
    mail(:to => emails.split(","),
         :subject => "#{comment.reply_name} replied for '#{post.title}'")

  end


end
