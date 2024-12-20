# test/models/cert_issue_request_test.rb
require "test_helper"

class DomainTest < ActiveSupport::TestCase
  def setup
    @attributes = {
      fqdn: "example4.com",
      users: [ "john.doe@example.com" ]
    }
    @domain = Domain.new(@attributes)
  end

  test "#new should set attributes from attributes argument" do
    @attributes.each do |key, value|
      assert_equal value, @domain.send(key), "Attribute #{key} was not set correctly"
    end
  end

  test "#valid? should be valid with valid attributes" do
    assert @domain.valid?
  end

  test "#valid? should require an fqdn" do
    @domain.fqdn = nil
    assert_not @domain.valid?
    assert_includes @domain.errors[:fqdn], "can't be blank"
  end
end
