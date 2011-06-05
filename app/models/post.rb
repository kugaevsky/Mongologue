#encoding: utf-8

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes
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
  validates_length_of :content, :maximum => 100000

  embeds_many :comments, :inverse_of => :post, index: true
  index :pid
  index "comments.pid"
  index :tags
  index :created_at
  index :updated_at
  index "comments.created_at"
  index "comments.updated_at"
  index :keywords
  before_save :process_tags_and_keywords
  before_save :render_content
  after_save :rebuild_tags
  after_destroy :rebuild_tags
  before_create :assign_pid

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
    tags.join(",") unless tags.nil?
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

  def remove_autotags
    self.tags = self.tags.to_set.subtract(autotags.values.flatten.to_set).to_a
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
    self.remove_autotags

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
    if !s.blank?
     terms = s.gsub(/ *, */,',').gsub(/[^!*0-9a-zа-яё ,]+/,'').strip.downcase.split(',')
     my_tags = Tag.without(:value).all.map(&:id).to_set

     crit = Post.without(:comments)
     keywords_and = []
     keywords_not = []
     tags_and = []
     tags_not = []

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
     crit=crit.all_in(:tags => tags_and) unless tags_and.empty?
     crit=crit.all_in(:keywords => keywords_and) unless keywords_and.empty?
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

      tmpcloud=Post.collection.map_reduce(map,reduce, :raw => true, :out => 'tagcloud' )
      Mongoid.master.collection('tagcloud').create_index([["value", Mongo::DESCENDING]])
      # Tag.all.each {|t| t.update_attribute(:link,"<a href='/?s=#{t.id}' title=#{t.value.to_i}>#{t.id}</a>" )}
    end

end
