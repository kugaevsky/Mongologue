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

  # Extremely slow, use only for bookmarking feature
  def self.page_number(pid, per_page = 20)
    @qposts = Post.only(:pid).order_by([:created_at, :desc])
    @position = 1
    @qposts.each do |pp|
      if pp.pid == pid then
        break
      end
      @position = @position + 1
    end
    return (@position.to_f/per_page).ceil
  end

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

  def tags_helper
    tags.join(",") unless tags.nil?
  end

  def tags_helper=(arg)
    if (arg.is_a? String)
      self.tags=arg.split(",")
    else
      self.tags=arg
    end
  end

  def to_param
    pid.to_s
  end

  def get_keywords
    sanitize(self.content,:tags =>%w()).downcase.scan(/[0-9a-zа-я]{3,}/).uniq
  end

  def process_tags_and_keywords
    # Remove leading and trailing spaces from every tag, force tags into downcase
    self.tags.each_with_index do |t, index|
      self.tags[index] = t.strip.downcase
    end
    # Remove duplicated tags if any
    self.tags.delete("")
    self.tags = self.tags.uniq
    # Finally add tagless tag if no tags specified and remove it, if there is any
    self.tags.delete("tagless")
    if self.tags.empty?
      self.tags << "tagless"
    end
    # Build list of keywords
    # Not sure if I should strip tags, need to think about this
    self.keywords=sanitize(self.content,:tags =>%w(a img blockquote)).downcase.scan(/[0-9a-zа-я]{3,}/).uniq

  end

  def render_content
    self.html_content = prepare_text(self.content)
  end

  # One crappy piece of code. Refactor.
  def self.my_search(s)
    if !s.blank?
     terms = s.split(',')
     my_tags = all_tags

     crit = Post.without(:comments)
     keywords_and = []
     keywords_not = []
     tags_and = []
     tags_not = []

     terms.each do |term|
       is_keyword = false
       is_tag = false
       is_not = false
       is_like = false

       t=term.strip.downcase
       is_not = true if t.chr=="!"
       if t.rindex("*")!=nil
         is_keyword = true
         is_tag = false
         is_like = true
       end

       t=t.gsub(/[^0-9a-zа-яё ]+/,'')
       if my_tags.select {|f| f["_id"] == t }==[]
         is_keyword = true
       else
         is_tag = true unless is_keyword == true
       end

       if is_like == true
         t= /^#{t}/
       end

       if is_keyword == true
         if is_not == true
           keywords_not << t
         else
           keywords_and << t
         end
       else
         if is_not == true
           tags_not << t
         else
           tags_and << t
         end
       end
     end
     if tags_and!=[]
       crit=crit.all_in(:tags => tags_and)
     end
     if keywords_and!=[]
       crit=crit.all_in(:keywords => keywords_and)
     end
     if tags_not!=[]
       crit=crit.not_in(:tags => tags_not)
     end
     if keywords_not!=[]
       crit=crit.not_in(:keywords => keywords_not)
     end

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
