require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  def setup
    @attributes = {
      request_id: "uuid1",
      action: "string1",
      result: "string2",
      subject: "string3",
      cert_common_name: "string4"
    }
    @audit_log = AuditLog.new(@attributes)
  end

  test "#new should set attributes from attributes argument" do
    @attributes.each do |key, value|
      assert_equal value, @audit_log.send(key), "Attribute #{key} was not set correctly"
    end
  end

  test "#new should not set attributes not in attributes argument" do
    [ :error, :kv_path ].each do |key|
      assert_nil @audit_log.send(key), "Attribute #{key} was not set correctly"
    end
  end

  test "#valid? should be valid with valid attributes" do
    assert @audit_log.valid?
  end

  test "#valid? should require an result" do
    @audit_log.result = nil
    assert_not @audit_log.valid?
    assert_includes @audit_log.errors[:result], "can't be blank"
  end
end
