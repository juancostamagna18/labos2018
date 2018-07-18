# frozen_string_literal: true

require './models/user'

# Consumer User sub class
class Consumer < User
  @db_filename = 'Consumer.json'
  @instances = {}

  def set_user(email, password, location)
    super
    save
  end

  def self.validate_hash(model_hash)
    super
  end
end
