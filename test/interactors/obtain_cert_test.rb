require "test_helper"

class ObtainCertTest < ActiveSupport::TestCase
  def setup
    @interactor = ObtainCert
    @cert = OpenStruct.new(certificate: "certificate", ca_chain: "ca_chain")
  end

  test ".call success" do
    request = Requests::CertIssueRequest.new
    mock = Minitest::Mock.new
    mock.expect :call, @cert, [ request ]
    Services::Certificate.stub :issue_cert, mock do
      context = @interactor.call(request: request)
      assert context.success?
      assert_equal @cert, context.cert
    end
  end

  test ".call failure" do
    request = Requests::CertIssueRequest.new
    mock = Minitest::Mock.new
    mock.expect :call, nil, [ request ]
    Services::Certificate.stub :issue_cert, mock do
      context = @interactor.call(request: request)
      assert context.failure?
      assert_nil context.cert
    end
  end
end
