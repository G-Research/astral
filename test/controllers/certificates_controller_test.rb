require "test_helper"

class CertificatesControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    post "/certificates"
    assert_response :success
    assert_includes response.parsed_body.keys, "ca_chain"
    assert_includes response.parsed_body.keys, "certificate"
  end
end
