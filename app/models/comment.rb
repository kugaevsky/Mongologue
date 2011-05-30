#encoding: utf-8

class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActionView::Helpers
  include ApplicationHelper


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
  before_save :process_content


  def process_content

     self.content=strip_comment(self.content)
     rules = {
          /\r\n/ => "\n",
          /\n\n+/ => "\n\n",
          /\n/ => "<br>\n",
      }

      rules.each do |regexp, replacement|
        self.content.gsub!(regexp, replacement)
        self.reply.gsub!(regexp, replacement) unless self.reply.nil?
      end
      self.content = typo(self.content)
      self.reply = typo(self.reply) unless self.reply.nil?
    return true
  end

  def to_param
    pid
  end

  def reverse_newlines
     rules = {
          /<br>/ => "\n"
      }
      rules.each do |regexp, replacement|
        self.reply.gsub!(regexp, replacement) unless self.reply.nil?
        # self.content.gsub!(regexp, replacement)
      end
  end

  protected

    def assign_pid
      self.pid ||= Sequence.generate_pid("post#{self._parent.pid}",:comment)
    end

end
