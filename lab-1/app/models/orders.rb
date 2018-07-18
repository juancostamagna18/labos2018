# frozen_string_literal: true

require './models/model'

# Places name, latitude and longitude
class Orders < Model
  @db_filename = 'Orders.json'
  @instances = {}

  attr_reader :provider_id
  attr_reader :items
  attr_reader :consumer_id
  attr_reader :status
  attr_reader :price

  def set_item(provider_id, items, consumer_id, status, price)
    @provider_id = provider_id
    @items = items
    @consumer_id = consumer_id
    @status = status
    @price = price
    save
  end

  def self.validate_hash(model_hash)
    model_hash.key?('provider_id')
    model_hash.key?('items')
    model_hash.key?('consumer_id')
    model_hash.key?('status')
    model_hash.key?('price')
    super
  end
end
