require 'digest'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :admin, :type => Boolean
  field :notes
  field :remember_token
  index :remember_token, :unique => true
  attr_protected :admin

  def remember_me!
    self['remember_token'] = encrypt("#{salt}--#{id}--#{Time.now.utc}")
    save
  end

  def self.authenticate(identity)
    user = find(:identity => identity)
    return nil  if user.nil?
    return user
  end

  def salt
    "bazinga"
  end 
	
  private
    def encrypt(string)
      secure_hash("#{salt}#{string}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end

end