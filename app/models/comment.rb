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
  validates_length_of :reply, :maximum => 1000
  validates_length_of :name, :maximum => 60
  validates_length_of :url, :maximum => 200
  before_create :assign_pid
  after_create :inc_counter
  after_destroy :dec_counter
  attr_accessible :content
  before_save :render_text
  embedded_in :post, :inverse_of => :comments

  def render_text
     self.content=sanitize(content,:tags =>%w(i b)) # add auto_link later
     self.content=prepare_text(self.content)
     self.reply=prepare_text(self.reply) unless self.reply.nil?
     return true
  end

  def to_param
    pid
  end

  protected

    def inc_counter
      self._parent.inc(:comments_counter,1)
    end

    def dec_counter
      self._parent.inc(:comments_counter,-1)
    end

    def assign_pid
      self.pid ||= Sequence.generate_pid("post#{self._parent.pid}",:comment)
    end

end
