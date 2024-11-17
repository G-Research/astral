require "test_helper"

class IdentityAliasTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
    @identity = Identity.new
    email = SecureRandom.hex(4)
    @identity.sub = email
    @alias_name = @identity.sub
    @group_name = SecureRandom.hex(4)
    @policies = %w[ my_policy1 my_policy2 ]
    @auth_path = "oidc"
  end

  test "#put_entity_alias creates an entity_alias" do
    assert_raise {  @client.read_entity_alias(@identity.sub, @alias_name, @auth_path) }
    @client.put_entity(@identity.sub, @policies)

    assert_kind_of Vault::Secret, @client.put_entity_alias(@identity.sub, @alias_name, @auth_path)
    entity_alias = @client.read_entity_alias(@identity.sub, @alias_name, @auth_path)
    assert_not_nil entity_alias
  end

  test "#put_entity_alias skips an existing entity_alias" do
    existing_alias = SecureRandom.hex
    assert_raise {  @client.read_entity_alias(@identity.sub, existing_alias, @auth_path) }
    @client.put_entity(@identity.sub, @policies)
    assert_kind_of Vault::Secret, @client.put_entity_alias(@identity.sub, existing_alias, @auth_path)
    entity_alias = @client.read_entity_alias(@identity.sub, existing_alias, @auth_path)
    assert_not_nil entity_alias

    # returns nil/no error when an existing alias exists
    assert_nil @client.put_entity_alias(@identity.sub, existing_alias, @auth_path)
    entity_alias = @client.read_entity_alias(@identity.sub, existing_alias, @auth_path)
    assert_not_nil entity_alias
  end

  test "#delete_entity_alias removes an entity_alias" do
    @client.put_entity(@identity.sub, @policies)

    assert_kind_of Vault::Secret, @client.put_entity_alias(@identity.sub, @alias_name, @auth_path)
    entity_alias = @client.read_entity_alias(@identity.sub, @alias_name, @auth_path)
    assert_not_nil entity_alias

    @client.delete_entity_alias(@identity.sub, @alias_name, @auth_path)
    assert_raise {  @client.read_entity_alias(@identity.sub, @alias_name, @auth_path) }
  end

  test "#put_group_alias creates a group_alias" do
    assert_raise {  @client.read_group_alias(@group_name, @alias_name, @auth_path) }
    @client.put_group(@group_name, @policies)

    assert_kind_of Vault::Secret, @client.put_group_alias(@group_name, @alias_name, @auth_path)
    group_alias = @client.read_group_alias(@group_name, @alias_name, @auth_path)
    assert_not_nil group_alias
  end

  test "#put_group_alias skips an existing group_alias" do
    existing_alias = SecureRandom.hex
    assert_raise {  @client.read_group_alias(@group_name, existing_alias, @auth_path) }
    @client.put_group(@group_name, @policies)
    assert_kind_of Vault::Secret, @client.put_group_alias(@group_name, existing_alias, @auth_path)
    group_alias = @client.read_group_alias(@group_name, existing_alias, @auth_path)
    assert_not_nil group_alias

    # returns nil/no error when an existing alias exists
    assert_nil @client.put_group_alias(@group_name, existing_alias, @auth_path)
    group_alias = @client.read_group_alias(@group_name, existing_alias, @auth_path)
    assert_not_nil group_alias
  end
end
