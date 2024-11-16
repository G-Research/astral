require "test_helper"

class PolicyTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
    @identity = Identity.new
    email = SecureRandom.hex(4)
    @identity.sub = email
  end

  test "#verify_policy raises when identity does not have the policy" do
    policy_name = "some/policy/name"
    @client.expects(:get_entity_data).with(@identity.sub).returns([ [ "some/other/policy" ], nil ])
    err = assert_raises { @client.verify_policy(@identity, policy_name) }
    assert_kind_of AuthError, err
  end

  test "#verify_policy permits identity having the policy" do
    policy_name = "some/policy/name"
    @client.expects(:get_entity_data).with(@identity.sub).returns([ [ policy_name ], nil ])
    assert_nil @client.verify_policy(@identity, policy_name)
  end

  test "#verify_policy checks identity.groups that overlap with supplied groups for the policy" do
    producer_policy = "some/policy/name"
    consumer_policy = "some/policy/other"
    @identity.groups = [ "my-group", "some-other-group" ]
    @client.expects(:get_entity_data).with(@identity.sub).returns([ [], nil ])
    @client.expects(:get_group_data).with("my-group").returns([ [], {} ])
    err = assert_raises { @client.verify_policy(@identity, producer_policy, [ "my-group", "yet-another-group" ], consumer_policy) }
    assert_kind_of AuthError, err
  end

  test "#verify_policy permits identity when one overlapping group (identity.groups and supplied groups) has the policy" do
    producer_policy = "some/policy/name"
    consumer_policy = "some/policy/other"
    @identity.groups = [ "my-group" ]
    @client.expects(:get_entity_data).with(@identity.sub).returns([ [], nil ])
    @client.expects(:get_group_data).with("my-group").returns([ [ consumer_policy ], {} ])
    assert_nil @client.verify_policy(@identity, producer_policy, [ "my-group" ], consumer_policy)
  end
end
