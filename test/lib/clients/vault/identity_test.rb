require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
    @identity = Identity.new
    email = SecureRandom.hex(4)
    @identity.sub = email
    @group_name = SecureRandom.hex(4)
    @policies = %w[ my_policy1 my_policy2 ]
  end

  test "#put_entity creates an entity" do
    entity =  @client.read_entity(@identity.sub)
    assert_nil entity

    @client.put_entity(@identity.sub, @policies)
    entity =  @client.read_entity(@identity.sub)
    assert_equal @policies, entity.data[:policies]
  end

 test "#put_entity merges policies for an existing entity" do
    existing_policies = %w[ policy_from_elsewhere ]
    existing_entity = SecureRandom.hex(4)

    @client.put_entity(existing_entity, existing_policies)
    policies, metadata =  @client.get_entity_data(existing_entity)
    assert_equal existing_policies, policies

    @client.put_entity(existing_entity, @policies)
    policies, metadata =  @client.get_entity_data(existing_entity)
    assert_equal @policies + existing_policies, policies
  end

  test "#delete_entity removes an entity" do
    @client.put_entity(@identity.sub, @policies)
    @client.delete_entity(@identity.sub)
    entity =  @client.read_entity(@identity.sub)
    assert_nil entity
  end

  test "#put_group creates an group" do
    policies, metadata =  @client.get_group_data(@group_name)
    assert_empty policies

    @client.put_group(@group_name, @policies)
    policies, metadata =  @client.get_group_data(@group_name)
    assert_equal @policies, policies
  end

  test "#put_group merges policies for an existing group" do
    existing_policies = %w[ policy_from_elsewhere ]
    existing_group = SecureRandom.hex(4)

    @client.put_group(existing_group, existing_policies)
    policies, metadata =  @client.get_group_data(existing_group)
    assert_equal existing_policies, policies

    @client.put_group(existing_group, @policies)
    policies, metadata =  @client.get_group_data(existing_group)
    assert_equal @policies + existing_policies, policies
  end
end
