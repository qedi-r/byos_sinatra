# frozen_string_literal: true

ENV['APP_ENV'] = 'test'
ENV['RACK_ENV'] = 'test'
ENV['BASE_URL'] = "http://baseurl"

require 'active_record'
require 'rack/test'
require 'nokogiri'
require 'database_cleaner/active_record'
require_relative '../app'

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.include Rack::Test::Methods

  ActiveRecord::Base.establish_connection(:test)
  ActiveRecord::Schema.verbose = false
  load 'db/schema.rb'

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  DatabaseCleaner.strategy = :truncation
  config.after do
    DatabaseCleaner.clean
  end

  def app
    Sinatra::Application
  end

  def get_and_parse(page, query_params = {}, env = {})
    get(page, query_params, env)
    @doc = Nokogiri::HTML(last_response.body)
    @doc
  end

  def get_json(page, query_params = {}, env = {})
    get(page, query_params, env)
    @doc = last_response
    expect(@doc.headers['content-type']).to eq('application/json')
    [@doc, JSON.parse(@doc.body)]
  end

  def post_json(page, data, params = {}, env = {})
    post(page, JSON.generate(data), params, env)
    @doc = last_response
    expect(@doc.headers['content-type']).to eq('application/json')
    [@doc, JSON.parse(@doc.body)]
  end
end

def create_basic_schedule()
  device = Device.create!({
    name: "Test Trmnl", 
    mac_address: 'aa:bb:cc:00:00:01',
  }) 
  schedule = Schedule.create!({
    name: "Test Basic Schedule",
    default_plugin: "plugin_a",
    schedule_events: [
      ScheduleEvent.create!({
        start_time: "00:00",
        end_time: "01:00",
        plugins: "plugin_se1_a,plugin_se1_b",
        update_frequency: 500,
      }),
      ScheduleEvent.create!({
        start_time: "01:00",
        end_time: "02:00",
        plugins: "plugin_se2_c,plugin_se2_d",
        update_frequency: 500,
      })
    ]
  })
  ActiveSchedule.create!({
    device: device,
    schedule: schedule,
  })

  ['plugin_a', 'plugin_b', 'plugin_se1_a', 'plugin_se1_b', 'plugin_se2_c'].each do |p|
    allow(ScreenFetcher)
      .to receive(:require_relative)
      .with("../plugins/lib/#{p}/#{p}")
      .and_return(true)
  end

  return [device, schedule]
end

def create_simple_schedule()
  device = Device.create!({
    name: "Test Trmnl", 
    mac_address: 'aa:bb:cc:00:00:01',
  }) 
  schedule = Schedule.create!({
    name: "Test Basic Schedule",
    default_plugin: "plugin_a",
  })
  ActiveSchedule.create!({
    device: device,
    schedule: schedule,
  })
   
  return [device, schedule]
end
