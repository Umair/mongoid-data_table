$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS  = File.join(File.dirname(__FILE__), "models")
SUPPORT = File.join(File.dirname(__FILE__), "support")
$LOAD_PATH.unshift(MODELS)
$LOAD_PATH.unshift(SUPPORT)

require 'rails'
require 'action_controller'
require 'mongoid'
require 'mongoid-data_table'
require 'mocha'
require 'rspec'
require 'kaminari'

LOGGER = ActiveSupport::BufferedLogger.new($stdout)

Mongoid.configure do |config|
  name = "mongoid_data_table_test"
  config.master = Mongo::Connection.new.db(name)
  config.logger = nil
end

if defined? ::Mongoid
  require 'kaminari/models/mongoid_extension'
  ::Mongoid::Document.send :include, Kaminari::MongoidExtension::Document
  ::Mongoid::Criteria.send :include, Kaminari::MongoidExtension::Criteria
end

Dir[ File.join(MODELS,  "**/*.rb") ].sort.each { |file| require file }
Dir[ File.join(SUPPORT, "**/*.rb") ].each { |file| require file }

RSpec.configure do |config|
  config.mock_with(:mocha)
  config.after(:suite) do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end