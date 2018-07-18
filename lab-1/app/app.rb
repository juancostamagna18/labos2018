require 'json'
require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/namespace'
require './models/locations'
require './models/consumer'
require './models/provider'
require './models/items'
require './models/orders'

# Main class of the application
class DeliveruApp < Sinatra::Application
  register Sinatra::Namespace

  enable :sessions unless test?

  ## Function to clean up the json requests.
  before do
    begin
      if request.body.read(1)
        request.body.rewind
        @request_payload = JSON.parse(request.body.read, symbolize_names: true)
      end
    rescue JSON::ParserError
      request.body.rewind
      puts "The body #{request.body.read} was not JSON"
    end
  end

  register do
    def auth
      condition do
        halt 401 unless session.key?(:logged_id) || settings.test?
      end
    end
  end

  ## API functions
  namespace '/api' do
    post '/login' do
      if Consumer.exists?('@email' => @request_payload[:email])
        user = Consumer.filter('@email' => @request_payload[:email],
                               '@password' => @request_payload[:password])
        return 403, 'Incorrect password' if user == []
        user = { id: user[0].id, isProvider: false }
        session[:logged_id] = user[:id]
        return 200, user.to_json
      elsif Provider.exists?('@email' => @request_payload[:email])
        user = Provider.filter('@email' => @request_payload[:email],
                               '@password' => @request_payload[:password])
        return 403, 'Incorrect password' if user == []
        user = { id: user[0].id, isProvider: true }
        session[:logged_id] = user[:id]
        return 200, user.to_json
      else
        return 403, 'Non existing user'
      end
    end

    post '/logout' do
      session.delete(:logged_id)
      return 200
    end

    post '/consumers' do
      return 400, 'No email' if @request_payload[:email].nil?
      return 400, 'No location' if @request_payload[:location].nil?
      return 409, 'Existing user' if Consumer.exists?('@email' =>
                                                      @request_payload[:email])
      return 409, 'Existing user' if Provider.exists?('@email' =>
                                                      @request_payload[:email])
      user = Consumer.new
      user.set_user(@request_payload[:email], @request_payload[:password],
                    @request_payload[:location])
      return 200, user.id.to_s
    end

    post '/providers' do
      return 400, 'No email' if @request_payload[:email].nil?
      return 400, 'No location' if @request_payload[:password].nil?
      return 400, 'No store name' if @request_payload[:store_name].nil?
      return 409, 'Existing user' if Consumer.exists?('@email' =>
                                                      @request_payload[:email])
      return 409, 'Existing user' if Provider.exists?('@email' =>
                                                      @request_payload[:email])
      return 409, 'Existing user' if Provider.exists?('@name' =>
                                                 @request_payload[:store_name])
      if @request_payload[:max_delivery_distance].nil?
        @request_payload[:max_delivery_distance] = 0
      end
      user = Provider.new
      user.set_user(@request_payload[:email],
                    @request_payload[:password],
                    @request_payload[:location],
                    @request_payload[:store_name],
                    @request_payload[:max_delivery_distance])
      return 200, user.id.to_s
    end

    post '/items' do
      return 400, 'No name' if @request_payload[:name].nil?
      return 400, 'No price' if @request_payload[:price].nil?
      return 404, 'Non existing provider' if
          Provider.exists?('@provider' => @request_payload[:provider])
      return 409, 'Duplicate Item for provider' if
          Items.exists?('@name' => @request_payload[:name], '@provider' =>
      @request_payload[:provider])
      item = Items.new
      item.set_item(@request_payload[:name],
                    @request_payload[:price].to_f,
                    @request_payload[:provider])
      return 200, item.to_json
    end

    post '/items/delete/:id' do
      item = Items.find(params[:id].to_i)
      return 404, 'Non existing item' if item.nil?
      return 403, 'Item not belonging to logged in provider' if
          item.provider != session[:logged_id]
      Items.delete(params[:id].to_i)
      return 200
    end

    get '/providers' do
      unless params[:location].nil?
        return 404, 'Non existing location' unless
            Locations.index?(params[:location].to_i)
      end
      providers = []
      Provider.all.each do |_, prov|
        if !Locations.index?(params[:location].to_i) ||
            prov.location == params[:location].to_i
          providers.push(id: prov.id, email: prov.email,
                         location: prov.location, store_name: prov.name)
        end
      end
      return 200, providers.to_json
    end

    get '/consumers' do
      consumers = []
      Consumer.all.each do |_, cons|
        consumers.push(id: cons.id, email: cons.email, location: cons.location)
      end
      return 200, consumers.to_json
    end

    post '/users/delete/:id' do
      user = Consumer.find(params[:id].to_i)
      if user.nil?
        user = Provider.find(params[:id].to_i)
        return 404, 'Non existing item' if user.nil?
        Provider.delete(params[:id].to_i)
        return 200
      end
      Consumer.delete(params[:id].to_i)
      return 200
    end

    get '/items' do
      unless params[:provider].nil?
        return 404, 'Non existing provider' unless
            Provider.index?(params[:provider].to_i)
      end
      items = []
      Items.all.each do |_, item|
        if item.provider == params[:provider].to_i
          items.push(id: item.id, name: item.name, price: item.price,
                     provider: item.provider)
        end
      end
      return 200, items.to_json
    end

    post '/orders' do
      total = 0
      return 400, 'No provider' if @request_payload[:provider].nil?
      return 400, 'No items' if @request_payload[:items].nil?
      return 400, 'No consumer' if @request_payload[:consumer].nil?
      return 404, 'Non existing provider' unless
          Provider.index?(@request_payload[:provider].to_i)
      @request_payload[:items].each do |item|
        itm = Items.find(item[:id])
        return 404, 'Non existing item' if itm.nil?
        total += (itm.price * item[:amount])
      end
      consumer = Consumer.find(@request_payload[:consumer].to_i)
      return 404, 'Non existing provider' if consumer.nil?
      return 400, 'Not enough balance' if consumer.balance < total
      consumer.balance -= total
      provider = Provider.find(@request_payload[:provider].to_i)
      provider.balance += total
      order = Orders.new
      order.set_item(@request_payload[:provider].to_i, @request_payload[:items],
                     @request_payload[:consumer].to_i, 'payed', total)
      return 200, order.id.to_s
    end

    get '/orders/detail/:id' do
      return 400, 'No ID' if params[:id].nil?
      order = Order.find(params[:id].to_i)
      return 404, 'Non existing order' if order.nil?
      info = []
      order.items.each do |item|
        it = Items.find(item.id)
        return 400, 'Non existing item' if it.nil?
        info.push(id: it.id, name: it.name, price: it.price,
                  amount: item.amount)
      end
      return 200, info.to_json
    end

    get '/orders' do
      return 400, 'No user_id' if params[:user_id].nil?
      return 404, 'Non existing consumer' unless
          Consumer.index?(params[:user_id].to_i)
      info = []
      consumer = Consumer.find(params[:user_id].to_i)
      Orders.filter('@consumer_id' => params[:user_id].to_i).each do |order|
        provider = Provider.find(order.provider_id)
        info.push(id: order.id, provider: provider.id,
                  provider_name: provider.name, consumer: consumer.id,
                  consumer_email: consumer.email,
                  consumer_location: consumer.location,
                  order_amount: order.price, status: order.status)
      end
      return 200, info.to_json
    end

    post '/deliver/:id' do
      return 404, 'Non existing order' unless Order.index?(params[:id].to_i)
      return 200
    end

    post '/orders/delete/:id' do
      order = Orders.find(params[:id].to_i)
      return 404, 'Non existing order' if order.nil?
      Orders.delete(params[:id].to_i)
      return 200
    end

    get '/users/:id' do
      return 400, 'No user_id' if params[:id].nil?
      user = Consumer.find(params[:id].to_i)
      user = Provider.find(params[:id].to_i) if user.nil?
      return 404, 'Non existing user' if user.nil?
      return 200, { email: user.email, balance: user.balance.to_i }.to_json
    end

    get '/locations' do
      location = []
      Locations.all.each do |_, loc|
        location.push(name: loc.name, id: loc.id)
      end
      return 200, location.to_json
    end

    get '*' do
      halt 404
    end
  end

  # This goes last as it is a catch all to redirect to the React Router
  get '/*' do
    erb :index
  end
end
