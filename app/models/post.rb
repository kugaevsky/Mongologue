class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes
  field :pid
  field :title
  field :content
  field :tags, type: Array
  field :comments_counter, type: Integer
  validates_presence_of :title
  validates_presence_of :content
  validates_length_of :title, :maximum => 60
  validates_length_of :content, :maximum => 100000

  embeds_many :comments, index: true
  index :pid
  index "comments.pid"
  index :tags
  index :created_at
  index :updated_at
  index "comments.created_at"
  index "comments.updated_at"
  before_save :make_tags_ok
  after_save :rebuild_tags
  after_destroy :rebuild_tags
  before_create :assign_pid

  def self.all_tags(limit = nil)
    tagcloud = Mongoid.master.collection('tagcloud')
    opts = { :sort => ["value", :desc] }
    opts[:limit] = limit unless limit.nil?
    tagcloud.find({}, opts).to_a    
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

  def make_tags_ok
    # Remove leading and trailing spaces from every tag, force tags into downcase
    self.tags.each_with_index do |t, index|
      self.tags[index] = t.strip.downcase
    end
    # Remove duplicated tags if any
    self.tags.delete("")
    self.tags=self.tags.uniq
    # Finally add tagless tag if no tags specified and remove it, if there is any
    self.tags.delete("tagless")
    if self.tags.size == 0
      self.tags << "tagless"
    end
  end

  def to_param
    pid
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
    end

end
