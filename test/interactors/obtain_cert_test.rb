require "test_helper"

class ObtainCertTest < ActiveSupport::TestCase
  def setup
    @interactor = ObtainCert
    @cert = OpenStruct.new(certificate: "certificate", ca_chain: "ca_chain")
  end

  test ".call success" do
    request = CertIssueRequest.new
    srv = Minitest::Mock.new
    srv.expect :issue_cert, @cert, [ request ]
    Services::CertificateService.stub :new, srv do
      context = @interactor.call(request: request)
      assert context.success?
      assert_equal @cert, context.cert
    end
  end

  test ".call failure" do
    request = CertIssueRequest.new
    srv = Minitest::Mock.new
    srv.expect :issue_cert, nil, [ request ]
    Services::CertificateService.stub :new, srv do
      context = @interactor.call(request: request)
      assert context.failure?
      assert_nil context.cert
    end
  end
end
