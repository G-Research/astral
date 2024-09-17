require "test_helper"

class AuditLoggingTest < ActiveSupport::TestCase
  def setup
    @domain = domains(:owner_match)
    @identity = Identity.new(subject: @domain.users_array.first)
    @cr = Requests::CertIssueRequest.new(common_name: @domain.fqdn)
    @log = Tempfile.new("log-test")
    Rails.configuration.astral[:audit_log_file] = @log.path
  end

  def teardown
    @log.close
    @log.unlink
  end

  test ".call will be logged as success" do
    Object.const_set("SuccessAction", Class.new do
                       include Interactor
                       include AuditLogging

                       def call
                       end
                     end)
    rslt = SuccessAction.call(identity: @identity, request: @cr)
    assert rslt.success?
    assert_match %Q("action":"SuccessAction","result":"success","error":null,"subject":"john.doe@example.com","cert_common_name":"example.com"), @log.readlines.last
  end

  test ".call will be logged as failure" do
    Object.const_set("FailAction", Class.new do
                       include Interactor
                       include AuditLogging

                       def call
                         context.fail!
                       end
                     end)
    rslt = FailAction.call(identity: @identity, request: @cr)
    assert_not rslt.success?
    assert_match %Q("action":"FailAction","result":"failure","error":null,"subject":"john.doe@example.com","cert_common_name":"example.com"), @log.readlines.last
  end
end
