class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActionView::Helpers

  field :pid
  field :name
  field :url
  field :ip
  field :content
  field :reply
  field :reply_name
  field :reply_url
  validates_length_of :content, :within => 5..500
  validates_length_of :reply, :maximum => 500
  validates_length_of :name, :maximum => 50
  validates_length_of :url, :maximum => 200
  before_create :assign_pid

  attr_accessible :content

  embedded_in :post, :inverse_of => :comments, :index => true
  before_save :strip_comment


  def strip_comment
    return true if self.content.nil?

    self.content=sanitize(self.content,:tags =>%w())

    cleanups = {
          /\r/ => '',
          /\n\n+/ => "\n\n",
          /[ \t]+/ => ' ',
      }    

    cleanups.each do |regexp, replacement|
      self.content.gsub!(regexp, replacement)
    end

    return true
  end

  def to_param
    pid
  end

  protected

    def assign_pid
      self.pid ||= Sequence.generate_pid("post#{self._parent}",:comment)
    end

end
