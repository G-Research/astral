require "test_helper"

class CertificatesTest < ActionDispatch::IntegrationTest
  test "#create with missing token" do
    post certificates_path
    assert_response :unauthorized
  end

  test "#create with faulty token (encoded with different signing key)" do
    post certificates_path, headers: { "Authorization" => "Bearer #{jwt_unauthorized}" }
    assert_response :unauthorized
  end

  test "#create authorized as owner" do
    post certificates_path, headers: { "Authorization" => "Bearer #{jwt_authorized}" },
         params: { cert_issue_request: { common_name: "example.com" } }
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

  test "#create authorized by group" do
    post certificates_path, headers: { "Authorization" => "Bearer #{jwt_authorized}" },
         params: { cert_issue_request: { common_name: "example2.com" } }
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

  test "#create not authorized by group" do
    post certificates_path, headers: { "Authorization" => "Bearer #{jwt_authorized}" },
         params: { cert_issue_request: { common_name: "example3.com" } }
    assert_response :unauthorized
  end
end
