class AuditLogFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, timestamp, _progname, message)
    # request_id is unique to the life of the api request
    request_id = ENV["action_dispatch.request_id"]
    json = {
      type: severity,
      time: timestamp,
      request_id: request_id,
      message: message
    }.to_json
    "#{json}\n"
  end
end
