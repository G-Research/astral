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

  test "#verify_policy looks for a role corresponding to consumer policy when supplied" do
    producer_policy = "some/policy/name"
    consumer_policy = "some/policy/other"
    read_oidc_response = OpenStruct.new(data: { bound_claims: { groups: [ "my-group" ] } })
    @client.expects(:get_entity_data).with(@identity.sub).returns([ [], nil ])
    @client.expects(:read_oidc_role).with("some_policy_other-role").returns(read_oidc_response)
    err = assert_raises { @client.verify_policy(@identity, producer_policy, consumer_policy) }
    assert_kind_of AuthError, err
  end

  test "#verify_policy permits identity having group linked to consumer policy role" do
    producer_policy = "some/policy/name"
    consumer_policy = "some/policy/other"
    @identity.groups = [ "my-group" ]
    read_oidc_response = OpenStruct.new(data: { bound_claims: { groups: [ "my-group" ] } })
    @client.expects(:get_entity_data).with(@identity.sub).returns([ [], nil ])
    @client.expects(:read_oidc_role).with("some_policy_other-role").returns(read_oidc_response)
    assert_nil @client.verify_policy(@identity, producer_policy, consumer_policy)
  end
end
