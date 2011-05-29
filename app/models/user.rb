require 'digest'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :admin, :type => Boolean
  field :identity
  field :remember_token
  field :notes
  field :encrypted_password
  field :salt
  index :remember_token, :unique => true
  index :identity, :unique => true

  attr_accessor :password

  attr_protected :admin, :salt, :encrypted_password

  validates_confirmation_of :password
  validates_uniqueness_of :identity
  validates_length_of   :password, :maximum => 40

  before_save :encrypt_password

  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end

  def remember_me!
    self.remember_token = encrypt("#{salt}--#{id}--#{Time.now.utc}")
    save
  end

  def self.authenticate(identity,submitted_password)
    user = where(:identity => identity).first
    return nil  if user.nil?
    return user if user.has_password?(submitted_password)
  end

  private

    def encrypt_password
      unless password.nil?
        self.salt = make_salt
        self.encrypted_password = encrypt(password)
      end
    end

    def make_salt
      secure_hash("#{Time.now.utc}#{password}")
    end

    def encrypt(string)
      secure_hash("#{salt}#{string}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end

end