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


SYMBOLS = [
    # экранирование спецсимволов
    # [/&/        , '&'  , '&amp;'    ,  '&#38;'],
    # [/</        , '<'  , '&lt'      ,  '&#60;'],
    # [/>/        , '>'  , '&gt'      ,  '&#62;'],

    # простые замены
    [/\(c\)/i   , '©'  , '&copy;'   , '&#169;'],
    [/\(tm\)/i  , '™'  , '&trade;'  , '&#153;'],
    [/\'/       , '’'  , '&rsquo;'  , '&#146;'],

    # кавычковая магия: обычные кавычки — ёлочки
    [/(^|\s)\"/ , '\1«', '\1&laquo;', '\1&#171;'],
    [/\"/ , '»', '&raquo;', '&#187;'],

    # кавычковая магия: вложенные кавычки заменяем на лапки
    [/(«|&laquo;)(.+)(?:«|&laquo;)(.+)(?:»|&raquo;)(.+)(»|&raquo;)/,
        '\1\2„\3“\4\5',
        '\1\2&bdquo;\3&ldquo;\4\5',
        '\1\2&#8222;\3&#147;\4\5',
    ],

    # тире
    [/-(\s)/    , '—\1', '&mdash;\1', '&#151;\1'],

    # короткие слова привязываем неразрывным пробелом;
    # прогоняем два раза, чтобы обработать расставленные в первом прогоне &nbsp;
    [/(^|\s)((?:\S|&[a-zA-Z#0-9]+;){1,2})(\s)/, '\1\2 ', '\1\2&nbsp;', '\1\2&#160;'],
    [/( |&nbsp;|&\#160;)((?:\S|&[a-zA-Z#0-9]+;){1,2})(\s)/, '\1\2 ', '\1\2&nbsp;', '\1\2&#160;']
]

# русская типографика
# аргументы:
#   line — текст, который нужно оттипографить
#   replacement — опция замены (:symbols — готовые символы, :names — буквенные
#        коды, :codes — числовые коды)
def typo(line, replacement = :names)
    symbols = case replacement
        when :symbols
            SYMBOLS.map{|regex, *replacements| [regex, replacements[0]]}
        when :names
            SYMBOLS.map{|regex, *replacements| [regex, replacements[1]]}
        when :codes
            SYMBOLS.map{|regex, *replacements| [regex, replacements[2]]}
        else
            raise(ArgumentError, "Expecting one of :symbols, :names, :codes, #{replacement.inspect} obtained")
    end

    cleanups = {
        /[\t ]+/ => ' ',
        /(\S+(?:-\S+)+)/ => '<nobr>\1</nobr>'
    }

    # заменяем спецсимволы
    symbols[0..2].each do |regexp, replacement|
        line.gsub!(regexp, replacement)
    end

    # прогоняем очистку пробельных символов
    cleanups.each do |regexp, replacement|
        line.gsub!(regexp, replacement)
    end

    # заменяем всё остальное
    symbols[3..-1].each do |regexp, replacement|
        line.gsub!(regexp, replacement)
    end

    line
  end

  def prepare_text(text)
    return simple_format(typo(text))
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

  def top_commented_posts
    @top_posts = Post.only(:pid, :title, :comments_counter).\
                      where(:created_at.gt => 1.month.ago).\
                      order_by([:comments_counter, :desc]).limit(11).to_ary
    outstr=String.new
    @top_posts.each do |post|
      outstr = outstr + link_to_post(post) + " (#{post.comments_counter})" + "<br />"
    end
    outstr.html_safe
  end

  # Don't ask me what's going on here and how it works, I had no idea when I wrote it
  # and so I have no idea now
  def you_are_here(post, winsize=11)
    @mystr=String.new

    before_posts = Post.only(:pid, :title, :created_at).\
                      where(:created_at.lte => post.created_at ).\
                      order_by([:created_at, :desc]).limit(winsize).to_ary
    after_posts = Post.only(:pid, :title, :created_at).\
                      where(:created_at.gt => post.created_at ).\
                      order_by([:created_at, :asc]).limit(winsize-1).to_ary
    @all_posts = after_posts.reverse.concat(before_posts)


    a1 = after_posts.size
    a2 = before_posts.size

    if (a2>winsize-1)
      d1 = a1>(winsize/2).ceil ? (a1-(winsize/2).ceil) : 0
      d2 = a1>(winsize/2).ceil ?  winsize-1+d1 : winsize-1
    else
      d2 = a2<(winsize/2).floor ? (winsize-1+a2-1) : winsize+(winsize/2).ceil
      d1 = a2<(winsize/2).floor ? (a2-1) : (winsize/2).ceil
    end

    for i in d1..d2 do
      m = @all_posts[i]
      if m.pid == post.pid
        @mystr=@mystr+"<b>#{m.title}</b><br />"
      else
        @mystr=@mystr+"#{link_to_post(m)}<br />"
      end
    end
    @mystr.html_safe

  end


end
