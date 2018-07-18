#\ -p 4000

require 'rack-proxy'
require 'sinatra'
require './app'

## Function to load all instances of model_class from the json file.
def load_model(model_class)
  begin
    file_content = File.read(model_class.db_filename)
    json_data = JSON.parse(file_content)
  rescue Errno::ENOENT
    # The file does not exists
    json_data = []
  end
  json_data.each do |data_hash|
    new_object = model_class.from_hash(data_hash)
    new_object.save
  end
end

warmup do
  # TODO remove unesesari prints
  puts 'Loading objects from json files'
  puts 'Loading Locations'
  load_model(Locations)
  puts Locations.all
  puts 'Loading Consumers'
  load_model(Consumer)
  puts Consumer.all
  puts 'Loading Provides'
  load_model(Provider)
  puts Provider.all
  puts 'Loading Items'
  load_model(Items)
  puts Items.all
  puts 'Loading Orders'
  load_model(Orders)
  puts Orders.all
  puts 'Done'
end

# Setting up routes
ROUTES = {
  '/' => DeliveruApp
}

# Run the application
run Rack::URLMap.new(ROUTES)
