class AuditLogFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, timestamp, _progname, message)
    # request_id is unique to the life of the api request
    request_id = Thread.current[:request_id]
    json = {
      type: severity,
      time: timestamp,
      request_id: request_id
    }
    if message.is_a? Hash
      json = json.merge(message)
    else
      json[:message] = message
    end
    "#{json.to_json}\n"
  end
end
