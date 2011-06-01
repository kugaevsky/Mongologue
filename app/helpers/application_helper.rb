#encoding: utf-8

module ApplicationHelper

  def site_info
    "Roses are red<br>Diamonds are blue<br>".html_safe
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
    output = "Posted #{time_ago_in_words(created)} ago."
	# if created!=updated
	#   output = "#{output} Updated #{time_ago_in_words(updated)} ago."
  #    end
    output
  end

  # List of "best" tags
  def fav_tags
    Set.new ["чебурашка","consequatur", "voluptas", "assumenda", "modi"]
  end

  # Note to self: link_to speed sucks balls
  def tags_cloud
    bo,bc = '<span class=favtag>','</span>'
    alist=String.new
    Post.all_tags.each do |hsh|
      id_text=fav_tags.include?(hsh['_id']) ? "#{bo}#{hsh['_id']}#{bc}" : hsh['_id']
      alist="#{alist}, <a href='?s=#{hsh['_id'].gsub(' ','%20')}' title=#{hsh['value'].to_i}>#{id_text}</a>"
    end
    alist.sub(', ','') # remove things at start
  end

  def tags_list(tags_array)
    tt = []
    tags_array.each do |t|
      tt << link_to(t, posts_path(:s => t))
    end
    tt.join(", ")
  end


  def gilenconf
  {
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
          /(^|\s)((?:\S|&[a-zA-Z#0-9]+;){1,2})(\s)/ => '\1\2 ',
          /( |&nbsp;|&\#160;)((?:\S|&[a-zA-Z#0-9]+;){1,2})(\s)/ => '\1\2 ',
          # длинное тире
          /-(\s)/ => '—\1',
          /\r\n/ => "\n",
          /\n\n+/ => "\n\n",
          /[ \t]+/ => ' ',
          /(\S+(?:-\S+)+)/ => '<nobr>\1</nobr>',
          /[ ]$/m => "",
          /^[ ]/m => ""
      }
      cleanups.each do |regexp, replacement|
        line.gsub!(regexp, replacement)
      end

    line=line.gilensize(gilenconf)
    line
  end

  def allowed_tags
    %w(i b)
  end

  def strip_comment(content)
    auto_link(sanitize(content,:tags =>allowed_tags))
  end

  def prepare_text(text)
    text = '<p>'+typo(text)+'</p>'
    rules = {
      /\n/ => "<br>\n",
      /<br>\n<br>\n/ => "</p>\n<p>"
    }
    rules.each do |regexp, replacement|
      text.gsub!(regexp, replacement)
    end
    return text
  end

  def unprepare_text(text)
    rules = {
        /<\/p>\n<p>/ => "<br>\n<br>\n",
        /<br>\n/ => "\n",
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
      # link_to_function "&uarr; UP &uarr;".html_safe,
      #                  "$( 'html, body' ).animate( { scrollTop: 0 }, 'slow' );"
    else
      link_to_unless scope.last_page?, name, {param_name => (scope.current_page + 1),
                                             :s => params[:s]},
                                              options.merge(:rel => 'next') do
        block.call if block
      end
    end
  end

end
