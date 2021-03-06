#encoding: utf-8

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActionView::Helpers
  include ApplicationHelper


  field :pid, type: Integer
  field :title
  field :content
  field :html_content
  field :tags, type: Array
  field :comments_counter, type: Integer
  field :keywords, type: Array

  validates_presence_of :title
  validates_presence_of :content
  validates_length_of :title, :maximum => 60
  validates_length_of :content, :maximum => 20000
  validates_length_of :tags_as_string, :maximum => 200

  embeds_many :comments, :inverse_of => :post
  index ({   pid: 1 })
  index ({ title: 1})
  index "comments.pid" => 1

  index ({tags: 1})
  index ({keywords: 1})

  index ({created_at: 1})
  index ({updated_at: 1})
  index "comments.created_at" => 1
  index "comments.updated_at" => 1
  before_save :process_tags_and_keywords
  before_save :render_content
  after_save :rebuild_tags
  after_destroy :rebuild_tags
  before_create :assign_pid

#  def cache_key
#    "#{self.class.name}:#{id}:#{updated_at.to_i}:#{comments_counter}"
#  end

  # Old method, now I have Tag model
  def self.all_tags(limit = nil)
    tagcloud = Mongoid.master.collection('tagcloud')
    opts = { :sort => ["value", :desc] }
    opts[:limit] = limit unless limit.nil?
    tagcloud.find({}, opts).to_set
  end

  # OMG Hack!
  def tags=(arg)
    if (arg.is_a? String)
      super arg.split(",")
    else
      super
    end
  end

  def tags_as_string
    tags.join(", ") unless tags.nil?
  end

  def tags_as_string=(arg)
    if (arg.is_a? String)
      self.tags=arg.split(",")
    end
  end

  def to_param
    pid.to_s
  end

  def get_keywords
    sanitize(self.content,:tags =>%w()).downcase.scan(/[0-9a-zа-я]{3,}/).uniq
  end

  def remove_autotags!
    post_autotags = autotags_flat&(self.tags.to_set)
    self.tags = self.tags.to_set.subtract(autotags_flat).to_a
    return post_autotags
  end

  def process_tags_and_keywords
    # Remove leading and trailing spaces from every tag, force tags into downcase
    self.tags.each_with_index do |t, index|
      self.tags[index] = t.strip.downcase
    end

    # Remove duplicated and empty tags if any
    self.tags.delete("")
    self.tags = self.tags.uniq

    # Add autotags
    # Delete any autotags, in case user entered any
    self.remove_autotags!

    # Add tagless first
    if self.tags.empty?
      self.tags << autotags[:tagless][0]
    end

    # Add html-content related tags

    # Add date
    self.tags << autotags[:year][self.created_at.year-2010]
    self.tags << autotags[:month][self.created_at.month-1]
    self.tags << autotags[:mday][self.created_at.mday-1]
    self.tags << autotags[:wday][self.created_at.wday-1]

    # Add html specific

    # Build list of keywords
    # Strip all html tags
    self.keywords=sanitize(self.content,:tags =>%w()).downcase.scan(/[0-9a-zа-я]{3,}/).uniq

    # Post size
    self.tags << case self.content.length
      when 1..140     then autotags[:size][0]
      when 141..999   then autotags[:size][1]
      when 1000..3999 then autotags[:size][2]
      else                 autotags[:size][3]
    end

    self.tags.delete("")
    self.tags.delete(nil)

  end

  def render_content
    self.html_content = prepare_text(self.content)
  end

  # One crappy piece of code. Refactor.
  def self.my_search(s)
    any_flag = false
    if !s.blank?
      terms = s.gsub(/ *, */,',').gsub(/[^!*0-9a-zа-яё ,]+/,'').strip.downcase.split(',')
      my_tags = Tag.only(:id).map(&:id).to_set

      crit = Post.all
      keywords_and = Array.new
      keywords_not = Array.new
      tags_and = Array.new
      tags_not = Array.new

      terms.each do |t|
        is_keyword = false
        is_tag = false
        is_not = false
        is_like = false

        is_not = true if t.start_with?("!")
        if t.end_with?("*")
         is_keyword = true
         is_like = true
        end

        t.gsub!(/[!*]/,'')

        if my_tags.include?(t)
         is_tag = true unless is_keyword
        else
         is_keyword = true
        end

        t= /^#{t}/ if is_like

        if is_keyword
         if is_not
           keywords_not << t
         else
           keywords_and << t
         end
        else
         if is_not
           tags_not << t
         else
           tags_and << t
         end
        end
     end

     if !any_flag
       crit=crit.all_in(:tags => tags_and) unless tags_and.empty?
       crit=crit.all_in(:keywords => keywords_and) unless keywords_and.empty?
     else
       crit=crit.any_in(:tags => tags_and) unless tags_and.empty?
       crit=crit.any_in(:keywords => keywords_and) unless keywords_and.empty?
     end

     crit=crit.not_in(:tags => tags_not) unless tags_not.empty?
     crit=crit.not_in(:keywords => keywords_not) unless keywords_not.empty?
     return crit
    else
     all
    end
  end

  protected

    def assign_pid
      self.pid ||= Sequence.generate_pid(nil,:post)
    end

    def rebuild_tags
      map     = "function() {
      if (!this.tags) {
          return;
      }

      for (index in this.tags) {
          emit(this.tags[index], 1);
      }
      }"

      reduce  = "function(previous, current) {
      var count = 0;

      for (index in current) {
          count += current[index];
      }
      return count;
      }"

      tmpcloud=Post.map_reduce(map, reduce).out(replace: "tagcloud")
      # Force db hit (wtf?)
      tmpcloud.each do |document|
       # p document
      end

      db = Mongoid::Sessions.default
      tagcloud = db[:tagcloud]
      tagcloud.indexes.create(value: -1)
    end

end
