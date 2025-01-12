require 'sinatra'
require 'forme'
require 'sinatra/activerecord'
require 'debug'
require 'pp'

require_relative 'config/initializers/tailwind_form'

current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file } # require models
Dir["#{current_dir}/services/*.rb"].each { |file| require file } # require services

configure do
  set :json_encoder, :to_json
end

# before do
#   headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
#   headers['Access-Control-Allow-Origin'] = '*'
#   headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
# end
#
# options '*' do
#   response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS,POST'
#   response.headers['Access-Control-Allow-Headers'] =
#     'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
# end

helpers do
  def url_for(path = '', options = {})
    scheme = options[:scheme] || request.scheme
    host = options[:host] || request.host
    port = options[:port] || request.port

    base = "#{scheme}://#{host}"
    if scheme == "http"
      base += ":#{port}" unless port == 80
    elsif scheme == "https"
      base += ":#{port}" unless port == 443
    end

    URI.join(base, path).to_s
  end

  def forme(model, options={}, &block)
    options[:wrapper] = :div
    options[:inputs_wrapper] = :div
    options[:input_defaults] = TailwindConfig.input_defaults
    options[:label_attr] = TailwindConfig.label_attr
    options[:before] = TailwindConfig.before
    options[:after] = TailwindConfig.after
    options[:labeler] = :explicit
    PP.pp(options)
    Forme.form(model, {}, options, &block)
  end
end


# DEVICE MANAGEMENT
get '/devices/?' do
  @devices = Device.all
  erb :"devices/index"
end

get '/devices/new' do
  @device = Device.new
  erb :"devices/new"
end

get '/devices/:id/delete' do
  @device = Device.find(params[:id])
  @device.destroy
  redirect to('/devices')
end

get '/devices/:id/edit' do
  @device = Device.find(params[:id])
  erb :"devices/edit"
end

patch '/devices/:id' do
  device = Device.find(params[:id])
  device.update(params[:device])
  redirect to('/devices')
end

post '/devices' do
  Device.create!(params[:device])
  redirect to('/devices')
end

# SCHEDULE MANAGEMENT
get '/schedules/?' do
  @schedules = Schedule.all
  erb :"schedules/index"
end

get '/schedules/new' do
  @schedule = Schedule.new
  erb :"schedules/new"
end

get '/schedules/:id/delete' do
  @schedule = Schedule.find(params[:id])
  @schedule.destroy
  redirect to('/schedules')
end

get '/schedules/:id/edit' do
  @schedule = Schedule.find(params[:id])
  erb :"schedules/edit"
end

patch '/schedules/:id' do
  device = Schedule.find(params[:id])
  device.update(params[:schedule])
  redirect to('/schedules')
end

post '/schedules' do
  Schedule.create!(params[:schedule])
  redirect to('/kevices')
end

# FIRMWARE SETUP
get '/api/setup' do
  content_type :json
  @device = Device.find_by_mac_address(env['HTTP_ID']) # => ie "41:B4:10:39:A1:24"

  if @device
    status = 200
    api_key = @device.api_key
    friendly_id = @device.friendly_id
    image_url =  url_for("/images/setup/setup-logo.bmp")
    message = "Welcome to TRMNL BYOS"

    { status:, api_key:, friendly_id:, image_url:, message: }.to_json
  else
    { status: 404, api_key: nil, friendly_id: nil, image_url: nil, message: 'MAC Address not registered' }.to_json
  end
end

# DISPLAY CONTENT
get '/api/display' do
  content_type :json
  @device = Device.find_by_api_key(env['HTTP_ACCESS_TOKEN'])
  screen = ScreenFetcher.call

  if @device
    {
      status: 0, # on core TRMNL server, status 202 loops device back to /api/setup unless User is connected, which doesn't apply here
      image_url: screen[:image_url],
      filename: screen[:filename],
      refresh_rate: 900,
      reset_firmware: false,
      update_firmware: false,
      firmware_url: nil,
      special_function: 'sleep'
    }.to_json
  else
    { status: 404 }.to_json
  end
end