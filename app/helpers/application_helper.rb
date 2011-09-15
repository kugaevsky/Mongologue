#encoding: utf-8

module ApplicationHelper
  include FastTypo

  # Return a title on a per-page basis.
  def page_title
    base_title = APP_CONFIG[:base_title]
    if @title.nil?
      base_title
    else
      "#{h @title} #{base_title}"
    end
  end

  def memc_write(time = 600)
    CACHE.clone

    begin
      @tstr="#{response.body}"
      CACHE.set("blog"+request.fullpath,@tstr,time,false);
    rescue
    end

    if request.fullpath=="/" or request.fullpath.start_with?("/?")
      begin
        aindex=CACHE.get("blog::index")
      rescue
        aindex=Set.new
      end
        if !aindex.include?(request.fullpath)
          aindex << "blog"+request.fullpath;
          CACHE.set("blog::index",Marshal.dump(aindex));
        end
    end
    CACHE.quit
  end

  def memc_purge(post)
    CACHE.clone
    begin
      CACHE.delete("blog/posts/#{post.pid}");
    rescue
    end
    CACHE.quit
  end

  def memc_purge_index
    CACHE.clone
      begin
        aindex=CACHE.get("blog::index")
        CACHE.delete("blog::index")
        aindex.each do |item|
          CACHE.delete(item);
        end
      rescue
      end
    CACHE.quit
  end


  # for caching
  def page_name
    if @posts.nil? || @posts.first.nil?
      if @post.nil?
        return "none"
      else
        return "p#{@post.pid}"
      end
    else
      return "p#{@posts.first.pid}"
    end
  end

  def prefix
    "admin" if authorized_admin?
  end

  def admin_url?
    params[:controller].index("admin") == 0
  end

  def site_info
    "Roses are red<br>Diamonds are blue<br>".html_safe
  end

  def mainpage?
    if controller.controller_name == "posts" and controller.action_name == "index"
      return true
    end
    return false
  end

  def showpostpage?
    if controller.controller_name == "posts" and controller.action_name == "show"
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
    Tag.order_by(:value => "desc").to_ary.each do |t|
      tid=autotags_flat.include?(t.id) ? "#{ao}#{t.id}#{ac}" :\
               fav_tags.include?(t.id) ? "#{bo}#{t.id}#{bc}" : t.id
      tlink="<a href='/?s=#{t.id}' title=#{t.value.to_i}>#{tid}</a>"
      tlist="#{tlist}, #{tlink}"
    end
    tlist.sub(', ','').html_safe # remove things at start
  end

  # we don't need any simple format
  def complex_format(text, html_options={}, options={})
    text = text ? text.to_str : ''
    text = text.dup if text.frozen?
    start_tag = tag('p', html_options, true)
    text.gsub!(/\r\n?/, "\n")
    text.gsub!(/\n\n+/, "\n\n")
    text.gsub!(/\n\n+/, "</p><br \>#{start_tag}")  # 2+ newline  -> paragraph + newline
    text.gsub!(/\n/, "</p>#{start_tag}") # 1 newline   -> paragraph
    text.insert 0, start_tag
    text.concat("</p>")
    text = sanitize(text) unless options[:sanitize] == false
    text
  end

  def prepare_text(text,options={:sanitize => false})

    line = "#{text}"

    #line=line.gilensize
    line=fast_typo(line)
    #line=fast_laquo(line)

    # Escape everything within <code> tag
    sub = line.scan(/(<code>)(.+?)(<\/code>)/um)
    if (!sub.nil?)
      sub.each do |s|
        line.gsub!(s[1],s[1].gsub(/</,'&lt;').gsub(/>/,'&gt;'))
      end
    end

    line.replace(complex_format(line,{},options))

    line.gsub!("\n","")
    line.gsub!("\r","")

    line

  end

  def unprepare_text(text)
    rules = {
        /&laquo;|&bdquo;|&ldquo;|&raquo;/ => '"',
        /&npsp;/ => '',
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

  def you_are_here(post, winsize=10)
    mystr=String.new

    pidmod = post.pid < (winsize/2).round ? ((winsize/2+1).round-post.pid) : 0

    posts = Post.only(:pid, :title, :created_at).\
                where(:pid.lte => post.pid+(winsize/2).round+pidmod ).\
                order_by([:created_at, :desc]).limit(winsize).to_ary

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
