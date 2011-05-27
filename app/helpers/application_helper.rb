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
    output = "Created #{time_ago_in_words(created)} ago."
	# if created!=updated
	#   output = "#{output} Updated #{time_ago_in_words(updated)} ago."
  #    end
    output
  end

  # List of "best" tags
  def fav_tags
    ["чебурашка","consequatur", "voluptas", "assumenda", "modi"]
  end

  def tags_cloud
    tt = Array.new
    bo,bc = "<span class='favtag'>".html_safe,"</span>".html_safe
    rawlist = Post.all_tags
    rawlist.each do |t|
      if fav_tags.include? t['_id']
        t_tag = bo+t['_id']+bc
      else
        t_tag = t['_id']
      end
      tt << link_to(t_tag, root_path(:tag => t['_id']), :title => t['value'].to_i)
      # tt << "test"
    end
    tt.join(", ")
  end

  def tags_list(tags_array)
    tt = []
    tags_array.each do |t|
      tt << link_to(t, posts_path(:tag => t))
    end
    tt.join(", ")
  end

  # Блок ниже взят со страницы http://faramag.com/answer/show/722

  SYMBOLS = [
      # экранирование спецсимволов
 #     [/&/        , '&'    , '&amp;'    ,  '&#38;'],
 #     [/</        , '<'    , '&lt'      ,  '&#60;'],
 #     [/>/        , '>'    , '&gt'      ,  '&#62;'],


      # простые замены
      [/\(c\)/i   , '©'    , '&copy;'   , '&#169;'],
      [/\(tm\)/i  , '™'    , '&trade;'  , '&#153;'],
      [/\'/       , '’'    , '&rsquo;'  , '&#146;'],

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
  def typa_graf(line, replacement = :symbols)
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
          # Приводим переводы строк к юникс-варианту
          /\r/ => "",
          # Два и более перевода строк превращаем в два
          /\n\n+/ => "\n\n",
          # Двойной перевод строк обозначает конец параграфа
          /\n\n/ => '</p><p>',
          # Одинарный перевод строки обозначает новую строку в параграфе
          /([^\n])(\n)([^\n])/ => '\1<br>\3',
          # Множественные пробелы превращаем в один
          /[ \t]+/ => ' ',
          # Ну и тут ещё какая-то хрень
          /(\S+(?:-\S+)+)/ => '<nobr>\1</nobr>'
      }

      # заменяем спецсимволы
      symbols[0..2].each do |regexp, replacement|
          line.gsub!(regexp, replacement)
      end

      # заменяем всё остальное
      symbols[3..-1].each do |regexp, replacement|
          line.gsub!(regexp, replacement)
      end

      # прогоняем очистку пробельных символов
      cleanups.each do |regexp, replacement|
          line.gsub!(regexp, replacement)
      end

      line
  end

  def display(content)
    auto_link(typa_graf(sanitize(content,:tags =>%w())))
  end

def link_to_next_page(scope, name, options = {}, &block)
  param_name = options.delete(:param_name) || Kaminari.config.param_name
  link_to_unless scope.last_page?, name, {param_name => (scope.current_page + 1)}, options.merge(:rel => 'next') do
    block.call if block
  end
end



end
