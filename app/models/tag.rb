class Tag
  include Mongoid::Document
  self.collection_name = 'tagcloud'
  identity :type => String
  field :value, :type => Integer


end