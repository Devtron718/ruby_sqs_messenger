require 'clockwork'
require './config/boot'
require './config/environment'

class SqsListener
  include Clockwork
  @@preprocessed_messages = []

  every(2.seconds, 'poll_sqs') { poll_and_process_messages! }

  class << self
    def listen_for(name, &processor)
      preprocessed_message = {
        name: name,
        processor: processor
      }

      unless @@preprocessed_messages.include?(preprocessed_message)
        @@preprocessed_messages << preprocessed_message
      end
    end

    private

    def poll_and_process_messages!
      puts "Polling right now!"
      @@preprocessed_messages.each do |preprocessed_message|
        queued_messages = get_messages(preprocessed_message)
        puts "Queued messages count: #{queued_messages.count}"
        queued_messages.each do |queued_message|
        # begin
          preprocessed_message[:processor].call(queued_message)
          remove_message(queued_message)
        # rescue => error
        #   # since exception was raised processing and message wasnt
        #   # removed, sqs will automatically retry
        #   # log error
        # end
        end
      end
    end

    def get_messages(preprocessed_message)
      response = client.receive_message({
        queue_url: "url",
        attribute_names: ["All"], # accepts All, Policy, VisibilityTimeout, MaximumMessageSize, MessageRetentionPeriod, ApproximateNumberOfMessages, ApproximateNumberOfMessagesNotVisible, CreatedTimestamp, LastModifiedTimestamp, QueueArn, ApproximateNumberOfMessagesDelayed, DelaySeconds, ReceiveMessageWaitTimeSeconds, RedrivePolicy, FifoQueue, ContentBasedDeduplication, KmsMasterKeyId, KmsDataKeyReusePeriodSeconds
        message_attribute_names: [preprocessed_message[:name]]
      })

      response.messages
    end

    def remove_message(queued_message)
      client.delete_message({
        queue_url: "url",
        receipt_handle: queued_message.receipt_handle
      })
    end

    def client
      Aws.config.update(
        region:      'us-east-1',
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                          ENV['AWS_SECRET_ACCESS_KEY'])
      )

      @@client ||= Aws::SQS::Client.new(
        region:      'us-east-1',
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                          ENV['AWS_SECRET_ACCESS_KEY'])
      )
    end
  end
end
