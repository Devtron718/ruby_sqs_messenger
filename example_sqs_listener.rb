require './config/boot'
require './config/environment'
require 'shipt_sqs_listener'

class ExampleSqsListener < SqsListener
  listen_for("store_location_update") {|message| puts "Processing #{message.message_id}"}
end
