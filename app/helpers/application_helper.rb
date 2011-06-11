#encoding: utf-8

module ApplicationHelper

  # Return a title on a per-page basis.
  def page_title
    base_title = "☢ Mongologue"
    if @title.nil?
      base_title
    else
      "#{h @title} #{base_title}"
    end
  end

  def site_info
    "Roses are red<br>Diamonds are blue<br>".html_safe
  end

  def mainpage?
    if controller_name == "posts" and controller.action_name == "index"
      return true
    end
    return false
  end

  def showpostpage?
    if controller_name == "posts" and controller.action_name == "show"
      return true
    end
    return false
  end

  def cache_unless_admin *args
    unless authorized_admin?
      cache args do
        yield
      end
    else
      yield
    end
  end

  def time_info(created,updated)
    "#{time_ago_in_words(created)} ago."
  end

  # Autotags:
  # 0 = tagless
  # 1 = html specific
  # 2 = year
  # 3 = month
  # 4 = day of week
  # 5 = post size
  # 6 = not safe for children (swearing)
  # You can customize these tags in any way you want
  # For example, you can use names instead of day numbers
  def autotags
    @@autotags ||= {
      :tagless => %w(tagless),
      :html =>    %w(img link quote code irony),
      :year =>    %w(2010 2011 2012 2013 2014 2015 2016),
      :month =>   %w(january february march april may june july august september october november december),
      :mday =>    %w(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
                     16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31),
      :wday =>    %w(monday tuesday wednesday thursday friday saturday sunday),
      :size =>    %w(tiny small big huge),
      :safety =>  %w(nsfc)
    }
  end

  def autotags_flat
    @@autotags_flat ||= autotags.values.flatten.to_set
  end


  # List of "best" tags
  def fav_tags
    Set.new %w(consequatur voluptas assumenda modi)
  end

  # Note to self: link_to speed sucks balls
  def tags_cloud
    bo,bc = '<span class=favtag>','</span>'
    ao,ac = '<span class=autotag>','</span>'
    tlist=String.new
    Tag.order_by(:value => "desc").each do |t|
      tid=autotags_flat.include?(t.id) ? "#{ao}#{t.id}#{ac}" :\
               fav_tags.include?(t.id) ? "#{bo}#{t.id}#{bc}" : t.id
      tlink="<a href='/?s=#{t.id}' title=#{t.value.to_i}>#{tid}</a>"
      tlist="#{tlist}, #{tlink}"
    end
    tlist.sub(', ','').html_safe # remove things at start
  end

  def prepare_text(text)

    line = "#{text}"

    line=line.gilensize

    # Escape everything within <code> tag
    sub = line.scan(/(<code>)(.+?)(<\/code>)/um)
    if (!sub.nil?)
      sub.each do |s|
        line.gsub!(s[1],s[1].gsub(/</,'&lt;').gsub(/>/,'&gt;'))
      end
    end

    line = simple_format(line)

    line.gsub!("\n","")
    line.gsub!("\r","")

    line

  end

  def unprepare_text(text)
    rules = {
        /&laquo;|&bdquo;|&ldquo;|&raquo;/ => '"',
        /&mdash;/ => '-',
        /&nbsp;/ => ' ',
        /<br \/>/ => '',
        /<p>/ => '',
        /<\/p>/ => '',
        /<nobr>/ => '',
        /<\/nobr>/ => ''
    }
    rules.each do |regexp, replacement|
      text.gsub!(regexp, replacement)
    end
    return text
  end

  def password_status_text(user)
    if user.encrypted_password.nil?
       link_to("No password protection. Set now.", edit_admin_user_path(current_user), :remote => true).html_safe
    else
       link_to("Change/remove password.", edit_admin_user_path(current_user), :remote => true).html_safe
    end
  end

  def link_to_next_page(scope, name, options = {}, &block)
    param_name = options.delete(:param_name) || Kaminari.config.param_name
    # Patched for search
    if scope.last_page?
      # put "up!" button permanently, experimental
      link_to_function "&uarr; UP &uarr;".html_safe,
                        "$( 'html, body' ).animate( { scrollTop: 0 }, 0 );"
    else
      link_to_unless scope.last_page?, name, {param_name => (scope.current_page + 1),
                                             :s => params[:s]},
                                              options.merge(:rel => 'next') do
        block.call if block
      end
    end
  end

  def top_commented_posts(maxsize=11)
    @top_posts = Post.only(:pid, :title, :comments_counter).\
                      where(:created_at.gt => 1.month.ago).\
                      order_by([:comments_counter, :desc]).limit(maxsize).to_ary
    outstr=String.new
    @top_posts.each do |post|
      outstr = outstr + link_to_post(post) + " (#{post.comments_counter.to_i})" + "<br />"
    end
    outstr.html_safe
  end

  def you_are_here(post, winsize=11)
    mystr=String.new

    posts = Post.only(:pid, :title, :created_at).\
                where(:pid.lte => post.pid+(winsize/2).ceil ).\
                order_by(:created_at, :desc).limit(winsize).to_ary

    posts.each do |m|
      if m.pid == post.pid
        mystr=mystr+"&rarr; <b>#{m.title}</b><br />"
      else
        mystr=mystr+"#{link_to_post(m)}<br />"
      end
    end
    mystr.html_safe

  end


end
