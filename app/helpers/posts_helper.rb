module PostsHelper

  def expire_post(post)
    expire_fragment(:controller => "posts", :action => "index", :id => post.pid)
    expire_fragment(:controller => "posts", :action => "show", :id => post.pid)
  end

  def expire_cloud
    expire_fragment('tagscloud')
  end

end
