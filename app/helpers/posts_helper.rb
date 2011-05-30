module PostsHelper

  def expire_post(post)
    expire_fragment(:controller => "posts", :action => "index", :id => post.pid, :action_suffix => true)
    expire_fragment(:controller => "posts", :action => "index", :id => post.pid, :action_suffix => false)
    expire_fragment(:controller => "posts", :action => "show", :id => post.pid, :action_suffix => true)
    expire_fragment(:controller => "posts", :action => "show", :id => post.pid, :action_suffix => false)
  end

  def expire_cloud
    expire_fragment('tagscloud')
  end

end
