require "test_helper"

class CertificatesControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    post "/certificates"
    assert_response :success
    %w[ ca_chain
        certificate
        expiration
        issuing_ca
        private_key
        private_key_type
        serial_number ].each do |key|
      assert_includes response.parsed_body.keys, key
    end
  end
end
