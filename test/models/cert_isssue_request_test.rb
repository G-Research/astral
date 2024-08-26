# test/models/cert_issue_request_test.rb
require "test_helper"

class CertIssueRequestTest < ActiveSupport::TestCase
  def setup
    @attributes = {
      common_name: "example.com",
      alt_names: [ "alt1.example.com", "alt2.example.com" ],
      exclude_cn_from_sans: true,
      format: "der",
      not_after: DateTime.now + 1.year,
      other_sans: [ "other1", "other2" ],
      private_key_format: "pkcs8",
      remove_roots_from_chain: true,
      ttl: 365,
      uri_sans: [ "http://example.com" ],
      ip_sans: [ "192.168.1.1" ],
      serial_number: 123456,
      client_flag: false,
      code_signing_flag: true,
      email_protection_flag: true,
      server_flag: false
    }
    @cert_issue_request = CertIssueRequest.new(@attributes)
  end

  test "#new should set attributes from attributes argument" do
    @attributes.each do |key, value|
      assert_equal value, @cert_issue_request.send(key), "Attribute #{key} was not set correctly"
    end
  end

  test "#valid? should be valid with valid attributes" do
    assert @cert_issue_request.valid?
  end

  test "#valid? should require a common_name" do
    @cert_issue_request.common_name = nil
    assert_not @cert_issue_request.valid?
    assert_includes @cert_issue_request.errors[:common_name], "can't be blank"
  end

  test "#valid? should require a valid format" do
    @cert_issue_request.format = "invalid_format"
    assert_not @cert_issue_request.valid?
    assert_includes @cert_issue_request.errors[:format], "is not included in the list"
  end

  test "#valid? should require a valid private_key_format" do
    @cert_issue_request.private_key_format = "invalid_format"
    assert_not @cert_issue_request.valid?
    assert_includes @cert_issue_request.errors[:private_key_format], "is not included in the list"
  end

  test "#new should have default values" do
    @cert_issue_request = CertIssueRequest.new
    assert_equal false, @cert_issue_request.exclude_cn_from_sans
    assert_equal "pem", @cert_issue_request.format
    assert_equal "pem", @cert_issue_request.private_key_format
    assert_equal false, @cert_issue_request.remove_roots_from_chain
    assert_equal Rails.configuration.astral[:cert_ttl], @cert_issue_request.ttl
    assert_equal true, @cert_issue_request.client_flag
    assert_equal false, @cert_issue_request.code_signing_flag
    assert_equal false, @cert_issue_request.email_protection_flag
    assert_equal true, @cert_issue_request.server_flag
  end

  test "#valid? should be false with default values" do
    @cert_issue_request = CertIssueRequest.new
    assert_not @cert_issue_request.valid?
  end

  test "#fqdns should return alt_names plus common_name" do
    assert_equal [ "alt1.example.com", "alt2.example.com", "example.com" ], @cert_issue_request.fqdns
  end
end
