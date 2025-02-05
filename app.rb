require 'dotenv/load'

require 'sinatra'
require 'sinatra/activerecord'
require 'debug'

require_relative 'config/initializers/tailwind_form'
require_relative 'config/initializers/subform_plugin'
require_relative 'config/initializers/explicit_forme_plugin'

# allows access on a local network at 192.168.x.x:4567; remove to scope to localhost:4567
set :bind, '0.0.0.0'
set :port, 4567

# make model, service classes accessible
%w[models services].each do |sub_dir|
  Dir["#{Dir.pwd}/#{sub_dir}/*.rb"].each { |file| require file }
end

helpers do
  def create_forme(model, is_edit, attrs={}, options={})
    attrs[:method] = :post
    options = TailwindConfig.options.merge(options)
    if model && model.persisted?
      attrs[:action] += "/#{model.id}" if model.id
      options[:before] = -> (form) {
        TailwindConfig.before.call(form)
        form.to_s << '<input name="_method" value="patch" type="hidden"/>'
      }
    end
    f = Forme::Form.new(model, options)
    f.extend(SubformsPlugin)
    f.extend(ExplicitFormePlugin)
    f.form_tag(attrs)
    return f
  end
end

configure do
  set :json_encoder, :to_json
end

configure :development, :test, :production do
  set :force_ssl, false
end

# DEVICE MANAGEMENT
def devices_form(device)
  create_forme(device, device.persisted?,
        {autocomplete:"off", action: "/devices"},
        {namespace: "device"})
end

get '/devices/?' do
  @devices = Device.all
  erb :"devices/index"
end

get '/devices/new' do
  @device = Device.new
  @form = devices_form(@device)
  erb :"devices/new"
end

get '/devices/:id/delete' do
  @device = Device.find(params[:id])
  @device.destroy
  redirect to('/devices')
end

get '/devices/:id/edit' do
  @device = Device.find(params[:id])
  @form = devices_form(@device)
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
def schedules_form(schedule)
  create_forme(schedule, schedule.persisted?,
        {autocomplete:"off", action: "/schedules"},
        {namespace: "schedule"})
end

get '/schedules/?' do
  @active_schedules = ActiveSchedule.all
  @schedules = Schedule.all
  @devices = Device.all
  erb :"schedules/index"
end

get '/schedules/new' do
  @schedule = Schedule.new
  @form = schedules_form(@schedule)
  erb :"schedules/new"
end

get '/schedules/:id/delete' do
  @schedule = Schedule.find(params[:id])
  @schedule.destroy
  redirect to('/schedules')
end

get '/scheduleEvent/:id/delete' do
  @schedule_event = ScheduleEvent.find(params[:id])
  @schedule_event.destroy
end

get '/schedules/:id/edit' do
  @schedule = Schedule.find(params[:id])
  @form = schedules_form(@schedule)
  erb :"schedules/edit"
end

patch '/schedules/:id' do
  schedule = Schedule.find(params[:id])
  schedule.update(params[:schedule])
  schedule_events_params = params[:schedule_events]
  schedule_events_params.each do |key,se|
    binding.break
    next if key == "-1"
    schedule_event = ScheduleEvent.find(key)
    schedule_event.update(se)
  end
  redirect to('/schedules')
end

post '/schedules' do
  schedule_params = params[:schedule]
  schedule_events_params = params[:schedule_events]
  schedule = Schedule.create!(schedule_params)
  schedule_events_params.each do |key,se|
    next if key == "-1"
    schedule.schedule_events.create(se)
  end
  redirect to('/schedules')
end

post '/schedules/activate' do
  device = Device.find(params[:device])
  schedule = Schedule.find(params[:schedule])
  binding.break
  ActiveSchedule.create!({
    device: device,
    schedule: schedule
  })
  redirect to('/schedules')
end

# FIRMWARE SETUP
get '/api/setup/' do
  content_type :json
  @device = Device.find_by_mac_address(env['HTTP_ID']) # => ie "41:B4:10:39:A1:24"

  if @device
    status = 200
    api_key = @device.api_key
    friendly_id = @device.friendly_id
    image_url = "#{ENV['BASE_URL']}/images/setup/setup-logo.bmp"
    message = "Welcome to TRMNL BYOS"

    { status:, api_key:, friendly_id:, image_url:, message: }.to_json
  else
    { status: 404, api_key: nil, friendly_id: nil, image_url: nil, message: 'MAC Address not registered' }.to_json
  end
end

# DISPLAY CONTENT
get '/api/display/' do
  content_type :json
  @device = Device.find_by_api_key(env['HTTP_ACCESS_TOKEN'])
  screen = ScreenFetcher.call

  if @device
    {
      status: 0, # on core TRMNL server, status 202 loops device back to /api/setup unless User is connected, which doesn't apply here
      image_url: screen[:image_url],
      filename: screen[:filename],
      refresh_rate: @device.refresh_interval,
      reset_firmware: false,
      update_firmware: false,
      firmware_url: nil,
      special_function: 'sleep'
    }.to_json
  else
    { status: 404 }.to_json
  end
end

# ERROR MESSAGES
post '/api/log' do
  puts "API/LOG: #{env}"
end
