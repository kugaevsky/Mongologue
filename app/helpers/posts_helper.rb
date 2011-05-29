module PostsHelper

  def expire_post(id)
    expire_fragment(:controller => "posts", :action => "index", :id => id)
    expire_fragment(:controller => "posts", :action => "show", :id => id)
  end

  def expire_cloud
    expire_fragment('tagscloud')
  end

end
