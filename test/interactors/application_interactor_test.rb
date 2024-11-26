require "test_helper"

class ApplicationInteractorTest < ActiveSupport::TestCase
  def setup
    @domain = domains(:owner_match)
    @identity = Identity.new(subject: @domain.users.first)
    @cr = Requests::CertIssueRequest.new(common_name: @domain.fqdn)
    Thread.current[:request_id] = "request_id"
  end

  test ".call will be logged as success" do
    Object.const_set("SuccessAction", Class.new(ApplicationInteractor) do
                       def call
                       ensure
                         audit_log
                       end
                     end)
    rslt = SuccessAction.call(identity: @identity, request: @cr)
    assert rslt.success?
    log = AuditLog.last
    expected = { "action"=>"SuccessAction", "result"=>"success", "subject"=>"john.doe@example.com", "cert_common_name"=>"example.com" }
    assert expected <= log.attributes
  end

  test ".call will be logged as failure" do
    Object.const_set("FailAction", Class.new(ApplicationInteractor) do
                       def call
                         context.fail!
                       ensure
                         audit_log
                       end
                     end)
    rslt = FailAction.call(identity: @identity, request: @cr)
    assert_not rslt.success?
    log = AuditLog.last
    expected = { "action"=>"FailAction", "result"=>"failure", "subject"=>"john.doe@example.com", "cert_common_name"=>"example.com" }
    assert expected <= log.attributes
  end
end
