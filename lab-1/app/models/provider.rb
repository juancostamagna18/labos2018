# frozen_string_literal: true

require './models/user'

# Provider User sub class whith name and max_distance
class Provider < User
  @db_filename = 'Provider.json'
  @instances = {}

  attr_accessor :name
  attr_accessor :max_distance

  def set_user(email, password, location, name, max_distance)
    @name = name
    @max_distance = max_distance
    super(email, password, location)
    save
  end

  def self.validate_hash(model_hash)
    model_hash.key?('name')
    model_hash.key?('max_distance')
    super
  end
end
