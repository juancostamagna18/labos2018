# frozen_string_literal: true

require './models/model'

# User base user clas
class User < Model
  @db_filename = 'Users.json'
  @instances = {}

  attr_accessor :email
  attr_accessor :password
  attr_accessor :location
  attr_accessor :balance

  def set_user(email, password, location)
    @email = email
    @password = password
    @location = location
    @balance = 0
  end

  def self.validate_hash(model_hash)
    model_hash.key?('email')
    model_hash.key?('password')
    model_hash.key?('location')
    model_hash.key?('balance')
    super
  end
end
