require "test_helper"

class SqlAuditLogTest < ActiveSupport::TestCase
  def setup
    @attributes = {
      request_id: "uuid1",
      action: "string1",
      result: "string2",
      subject: "string3",
      cert_common_name: "string4"
    }
    @sql_audit_log = SqlAuditLog.new(@attributes)
  end

  test "#new should set attributes from attributes argument" do
    @attributes.each do |key, value|
      assert_equal value, @sql_audit_log.send(key), "Attribute #{key} was not set correctly"
    end
  end

  test "#valid? should be valid with valid attributes" do
    assert @sql_audit_log.valid?
  end

  test "#valid? should require an result" do
    @sql_audit_log.result = nil
    assert_not @sql_audit_log.valid?
    assert_includes @sql_audit_log.errors[:result], "can't be blank"
  end
end
