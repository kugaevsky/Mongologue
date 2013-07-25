class Tag
  include Mongoid::Document
  field :_id, type: String
  field :value, :type => Integer
  store_in collection: "tagcloud"

end