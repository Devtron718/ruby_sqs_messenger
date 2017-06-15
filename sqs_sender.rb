class SqsSender
  def self.send(message_name, body)
    client.send_message({
      queue_url: "url",
      message_body: body.to_json,
      message_attributes: {
        "Name" => {
          string_value: message_name,
          data_type: "String", # required
        }
      }
    })
  end

  private

  def self.client
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
