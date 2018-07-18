# frozen_string_literal: true

require './models/model'

# Places name, latitude and longitude
class Items < Model
  @db_filename = 'Items.json'
  @instances = {}

  attr_reader :name
  attr_reader :price
  attr_reader :provider

  def set_item(name, price, provider)
    @name = name
    @price = price
    @provider = provider
    save
  end

  def self.validate_hash(model_hash)
    model_hash.key?('name')
    model_hash.key?('price')
    model_hash.key?('provider')
    super
  end
end
