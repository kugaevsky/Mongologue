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
  validates_length_of :content, :within => 5..600
  validates_length_of :reply, :maximum => 500
  validates_length_of :name, :maximum => 50
  validates_length_of :url, :maximum => 200
  before_create :assign_pid

  attr_accessible :content

  embedded_in :post, :inverse_of => :comments, :index => true
  before_save :prepare_text


  def prepare_text
     self.content=strip_comment(self.content)
     self.content = '<p>'+typo(self.content)+'</p>'
     self.reply = '<p>'+typo(self.reply)+'</p>' unless self.reply.nil?

     rules = {
        /\n/ => "<br>\n",
        /<br>\n<br>\n/ => "</p>\n<p>"
      }

      rules.each do |regexp, replacement|
        self.content.gsub!(regexp, replacement)
        self.reply.gsub!(regexp, replacement) unless self.reply.nil?
      end

    return true
  end

  def to_param
    pid
  end

  def unprepare_text
    rules = {
          /<\/p>\n<p>/ => "<br>\n<br>\n",
          /<br>\n/ => "\n",
          /<p>/ => '',
          /<\/p>/ => '',
          /<nobr>/ => '',
          /<\/nobr>/ => ''
      }

      rules.each do |regexp, replacement|
        self.content.gsub!(regexp, replacement)
        self.reply.gsub!(regexp, replacement) unless self.reply.nil?
      end

      self.content=sanitize(self.content,:tags =>%())

      return true
  end

  protected

    def assign_pid
      self.pid ||= Sequence.generate_pid("post#{self._parent.pid}",:comment)
    end

end
