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

  def edit_forme(model, attributes={}, options={}, &block)
    merged_options = TailwindConfig.options.merge(options)
    attributes[:method] = :post
    merged_options[:before] = -> (form) {
      TailwindConfig.before.call(form)
      form.to_s << '<input name="_method" value="patch" type="hidden"/>'
    }
    Forme.form(model, attributes, merged_options, &block)
  end

  def forme(model, attributes={}, options={}, &block)
    attributes[:method] = :post
    merged_options = TailwindConfig.options.merge(options)
    Forme.form(model, attributes, merged_options, &block)
  end

  def explicit_forme(model, attributes={}, options={})
    attributes[:method] = :post
    merged_options = TailwindConfig.options.merge(options)
    (f, attrs, b) = Forme::Form.form_args(model, attributes, merged_options)
    return f
  end
end

get '/' do
  @page_title = "Index"
  erb :"index"
end

# DEVICE MANAGEMENT
get '/devices/?' do
  @devices = Device.all
  @page_title = "Register a device"
  erb :"devices/index"
end

get '/devices/new' do
  @device = Device.new
  @page_title = "Devices"
  erb :"devices/new"
end

get '/devices/:id/delete' do
  @device = Device.find(params[:id])
  @device.destroy
  redirect to('/devices')
end

get '/devices/:id/edit' do
  @device = Device.find(params[:id])
  @page_title = "Edit " + @device.name
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
  @page_title = "Current schedules"
  erb :"schedule/index"
end

get '/schedules/new' do
  @schedule = Schedule.new
  @page_title = "Create a new schedule"
  erb :"schedule/new"
end

## SCHEDULE EVENTS
get '/schedule_event/?' do
  @schedule_event = ScheduleEvent.all
  @page_title = "Current schedule events"
  erb :"schedule_event/index"
end

get '/schedule_event/new' do
  @schedule_event = ScheduleEvent.new
  @page_title = "Create a schedule"
  erb :"schedule_event/new"
end

get '/schedule_event/:id/delete' do
  @schedule_event = ScheduleEvent.find(params[:id])
  @schedule_event.destroy
  redirect to('/schedule_event')
end

get '/schedule_event/:id/edit' do
  @schedule_event = ScheduleEvent.find(params[:id])
  erb :"schedule_event/edit"
end

patch '/schedule_event/:id' do
  device = ScheduleEvent.find(params[:id])
  device.update(params[:schedule])
  redirect to('/schedule_event')
end

post '/schedule_event' do
  ScheduleEvent.create!(params[:schedule])
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