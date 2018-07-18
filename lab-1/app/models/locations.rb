# frozen_string_literal: true

require './models/model'

# Places name, latitude and longitude
class Locations < Model
  @db_filename = 'Locations.json'
  @instances = {}

  attr_reader :latitude
  attr_reader :longitude
  attr_reader :name

  def set_location(name, latitude, longitude)
    @name = name
    @latitude = latitude
    @longitude = longitude
    save
  end

  def self.validate_hash(model_hash)
    model_hash.key?('name')
    model_hash.key?('latitude')
    model_hash.key?('longitude')
    super
  end
end
