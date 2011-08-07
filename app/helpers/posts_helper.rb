module PostsHelper

  def link_to_edit(post)
    @edtmplt ||= link_to('Edit', edit_admin_post_path(post), :remote => true)
    return @edtmplt.gsub(/\d+/,post.pid.to_s).html_safe
  end

  def link_to_delete(post)
    @deltmplt ||= link_to('Delete', admin_post_path(post), :confirm => 'Are you sure?', :method => :delete,
                                                        :remote => true)
    return @deltmplt.gsub(/\d+/,post.pid.to_s).html_safe
  end

  def link_to_expand_comments(post,counter)
    @extmplt ||=  link_to "Comments: #{counter}", expand_comments_post_path(post),
                          :remote => true, :id => "showc#{post.pid}"
    return @extmplt.gsub(/\/\d+/,"/#{post.pid}").gsub(/c\d+/,"c#{post.pid}").gsub(/: \d+/,": #{counter}").html_safe
  end

  def link_to_collapse_comments(post,counter)
    @cotmplt ||=  link_to "Comments: #{counter}", collapse_comments_post_path(post),
                          :remote => true, :id => "showc#{post.pid}"
    return @cotmplt.gsub(/\/\d+/,"/#{post.pid}").gsub(/c\d+/,"c#{post.pid}").gsub(/: \d+/,": #{counter}").html_safe
  end

  def link_to_post(post)
    @pstmplt ||= link_to(post.title, post)
    return @pstmplt.gsub(/\d+/,post.pid.to_s).gsub(/>.+</,">#{post.title}<").html_safe
  end

  def tags_list(tags_array)
    tlist = String.new
    tags_array.each do |t|
      tlist="#{tlist}, <a href='/?s=#{t}'>#{t}</a>"
    end
    tlist.sub(', ','').html_safe
  end

  def gplus_post(post)
    "<g:plusone size='small' href='#{polymorphic_url(post)}'></g:plusone>".html_safe
  end

end
