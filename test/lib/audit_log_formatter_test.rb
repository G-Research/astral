require "test_helper"

class AuditLogFormatterTest < ActiveSupport::TestCase
  setup do
    Thread.current[:request_id] = nil
  end

  test "#call formats logformatter inputs as json" do
    t = Time.now
    result = AuditLogFormatter.new.call("info", t, nil, "some message")
    assert_equal %Q({"type":"info","time":"#{t}","request_id":null,"message":"some message"}\n), result
  end

  test "#call accepts and merges a Hash type for the message" do
    t = Time.now
    result = AuditLogFormatter.new.call("info", t, nil, { key: "some message", key2: "another" })
    assert_equal %Q({"type":"info","time":"#{t}","request_id":null,"key":"some message","key2":"another"}\n), result
  end

  test "#call can render a thread local request_id" do
    t = Time.now
    req_id = SecureRandom.hex
    Thread.stub :current, { request_id: req_id } do
      result = AuditLogFormatter.new.call("info", t, nil, { key: "some message" })
      assert_equal %Q({"type":"info","time":"#{t}","request_id":"#{req_id}","key":"some message"}\n), result
    end
  end
end
