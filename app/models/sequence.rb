class Sequence
  include Mongoid::Document
  field :parent
  field :object

  index ({parent: 1})
  index ({object: 1})

  def self.generate_pid(parent,object)
    @seq=where(:parent => parent, :object => object).first || 
         create(:parent => parent, :object => object)
    @seq.inc(:last_pid,1).to_s
  end

end