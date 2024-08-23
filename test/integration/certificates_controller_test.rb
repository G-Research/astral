require "test_helper"

class CertificatesControllerTest < ActionDispatch::IntegrationTest
  test "create unauthorized" do
    post certificates_path
    assert_response :unauthorized
  end

  test "create with faulty token (encoded with different signing key)" do
    jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhcHBsaWNhdGlvbl9uYW1lIiwiY29tbW9uX25hbWUiOiJleGFtcGxlLmNvbSIsImlwX3NhbnMiOiIxMC4wLjEuMTAwIn0.gEUyaZcARiBQNq2RUwZU0MdFXqthyo_oSQ8DAgKvxCs"
    post certificates_path, headers: { "Authorization" => "Bearer #{jwt}" }
    assert_response :unauthorized
  end

  test "create authorized" do
    jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huLmRvZUBleGFtcGxlLmNvbSIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMiwiZ3JvdXBzIjpbImdyb3VwMSIsImdyb3VwMiJdLCJhdWQiOiJhc3RyYWwifQ.tfRLXmE_eq-piP88_clwPWrYfMAQbCJAeZQI6OFxZSI"
    post certificates_path, headers: { "Authorization" => "Bearer #{jwt}" },
         params: { common_name: "example.com" }
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
