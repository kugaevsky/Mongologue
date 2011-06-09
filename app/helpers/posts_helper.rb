module PostsHelper

  def link_to_edit(post)
    @edtmplt ||= link_to('Edit', edit_admin_post_path(post), :remote => true)
    return @edtmplt.gsub(/\d+/,post.pid.to_s)
  end

  def link_to_delete(post)
    @deltmplt ||= link_to('Delete', admin_post_path(post), :confirm => 'Are you sure?', :method => :delete,
                                                        :remote => true)
    return @deltmplt.gsub(/\d+/,post.pid.to_s)
  end

  def link_to_expand_comments(post,counter)
    @extmplt ||=  link_to "Comments: #{counter}", expand_comments_post_path(post),
                          :remote => true, :id => "showc#{post.pid}"
    return @extmplt.gsub(/\/\d+/,"/#{post.pid}").gsub(/c\d+/,"c#{post.pid}").gsub(/: \d+/,": #{counter}")
  end

  def link_to_collapse_comments(post,counter)
    @cotmplt ||=  link_to "Comments: #{counter}", collapse_comments_post_path(post),
                          :remote => true, :id => "showc#{post.pid}"
    return @cotmplt.gsub(/\/\d+/,"/#{post.pid}").gsub(/c\d+/,"c#{post.pid}").gsub(/: \d+/,": #{counter}")
  end

  def expire_post_with_comments(post)
    expire_post(post)
    expire_comments(post)
  end

  def expire_post(post)
    expire_fragment("p#{post.pid}@true")
    expire_fragment("p#{post.pid}@false")
  end

  def expire_comments(post)
    expire_fragment("pc#{post.pid}@true")
    expire_fragment("pc#{post.pid}@false")
  end

  def expire_cloud
    expire_fragment('tagscloud')
    expire_fragment('sitemap')
  end

  def expire_sitemap
    expire_fragment('sitemap')
  end

end
