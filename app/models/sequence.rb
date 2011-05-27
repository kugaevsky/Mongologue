class Sequence
  include Mongoid::Document
  
  field :post, :type => Integer
  field :comment, :type => Integer

end