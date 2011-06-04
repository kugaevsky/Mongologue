module PostsHelper

  def expire_post(post)
    expire_fragment("index@posts@#{post.pid}@true")
    expire_fragment("index@posts@#{post.pid}@false")
    expire_fragment("show@posts@#{post.pid}@true")
    expire_fragment("show@posts@#{post.pid}@false")
  end

  def expire_cloud
    expire_fragment('tagscloud')
    expire_fragment('sitemap')
  end

  def expire_sitemap
    expire_fragment('sitemap')
  end

end
