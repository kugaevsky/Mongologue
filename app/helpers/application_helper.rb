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
    Set.new ["consequatur", "voluptas", "assumenda", "modi"]
  end

  # Note to self: link_to speed sucks balls
  def tags_cloud
    bo,bc = '<span class=favtag>','</span>'
    ao,ac = '<span class=autotag>','</span>'
    tlist=String.new
    Tag.order_by(:value => "desc").each do |t|
      tid=autotags_flat.include?(t.id) ? "#{ao}#{t.id}#{ac}" : fav_tags.include?(t.id) ? "#{bo}#{t.id}#{bc}" : t.id
      tlink="<a href='/?s=#{t.id}' title=#{t.value.to_i}>#{tid}</a>"
      tlist="#{tlist}, #{tlink}"
    end
    tlist.sub(', ','').html_safe # remove things at start
  end

  def gilenconf
    @@gilenconf ||= {
     "inches"    => false,   # преобразовывать дюймы в знак дюйма;
     "laquo"     => true,    # кавычки-ёлочки
     "quotes"    => true,    # кавычки-английские лапки
     "dash"      => true,    # короткое тире (150)
     "emdash"    => true,    # длинное тире двумя минусами (151)
     "initials"  => false,   # тонкие шпации в инициалах
     "copypaste" => false,   # замена непечатных и "специальных" юникодных символов на entities
     "(c)"       => true,    # обрабатывать знак копирайта
     "(r)"       => true,
     "(tm)"      => true,
     "(p)"       => false,
     "acronyms"  => false,   # Акронимы с пояснениями - ЖЗЛ(Жизнь Замечатльных Людей)
     "+-"        => true,    # спецсимволы, какие - понятно
     "degrees"   => false,    # знак градуса
     "dashglue"  => false, "wordglue" => false, # приклеивание предлогов и дефисов
     "spacing"   => true,    # запятые и пробелы, перестановка
     "phones"    => false,    # обработка телефонов
     "html"      => true,    # разрешение использования тагов html
     "de_nobr"   => false,   # при true все <nobr/> заменяются на <span class="nobr"/>
     "raw_output" => true,   # выводить UTF-8 вместо entities
     "skip_attr" => true,    # при true не отрабатывать типографику в атрибутах тегов
     "skip_code" => true,    # при true не отрабатывать типографику внутри <code/>, <tt/>, CDATA
     "enforce_en_quotes" => false, # только латинские кавычки
     "enforce_ru_quotes" => false, # только русские кавычки (enforce_en_quotes при этом игнорируется)
  }
  end

  def typo(line)
    # Доделаем часть работы
    cleanups = {
          /\(c\)/i => '©',
          # короткие слова привязываем неразрывным пробелом;
          # прогоняем два раза, чтобы обработать расставленные в первом прогоне &nbsp;
#         /(^|\s)((?:\S|&[a-zA-Z#0-9]+;){1,2})(\s)/ => '\1\2 ',
#         /( |&nbsp;|&\#160;)((?:\S|&[a-zA-Z#0-9]+;){1,2})(\s)/ => '\1\2 ',
          # длинное тире
          /-(\s)/ => '—\1',
          /\r\n/ => "\n",
          /\n\n+/ => "\n\n",
          /[ \t]+/ => ' ',
#          /(\S+(?:-\S+)+)/ => '<nobr>\1</nobr>',
          /[ ]$/m => "",
          /^[ ]/m => ""
      }
      cleanups.each do |regexp, replacement|
        line.gsub!(regexp, replacement)
      end

    line.gilensize(gilenconf)
  end

  def prepare_text(text)
    return simple_format(typo(text))
  end

  def unprepare_text(text)
    rules = {
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

end
