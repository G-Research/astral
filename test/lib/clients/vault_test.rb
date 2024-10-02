require "test_helper"

class VaultTest < ActiveSupport::TestCase
  attr_reader :random_mount
  attr_reader :policies
  attr_reader :entity_name
  attr_reader :alias_name
  setup do
    @client = Clients::Vault
    @random_mount = SecureRandom.hex(4)
    @policies = SecureRandom.hex(4)
    @entity_name = SecureRandom.hex(4)
    @alias_name = SecureRandom.hex(4)
  end

  teardown do
    vault_client.sys.unmount(random_mount)
  end

  test "#configure_kv" do
    @client.stub :kv_mount, random_mount do
      assert @client.configure_kv
      engines = vault_client.sys.mounts
      assert_equal "kv", engines[random_mount.to_sym].type
    end
  end

  test "#configure_pki" do
    @client.stub :intermediate_ca_mount, random_mount do
      assert @client.configure_pki
      engines = vault_client.sys.mounts
      assert_equal "pki", engines[random_mount.to_sym].type

      read_cert = vault_client.logical.read("#{random_mount}/cert/ca").data[:certificate]
      assert_match "BEGIN CERTIFICATE", read_cert

      cluster_config = vault_client.logical.read("#{random_mount}/config/cluster").data
      assert_equal "#{vault_addr}/v1/#{random_mount}", cluster_config[:path]
      assert_equal "#{vault_addr}/v1/#{random_mount}", cluster_config[:aia_path]

      role_config = vault_client.logical.read("#{random_mount}/roles/astral").data
      assert_not_nil role_config[:issuer_ref]
      assert_equal 720.hours, role_config[:max_ttl]
      assert_equal true, role_config[:allow_any_name]
     end
  end

  test "#entity" do
    entity =  @client.read_entity(@entity_name)
    assert_nil entity

    @client.put_entity(@entity_name, @policies)
    entity =  @client.read_entity(@entity_name)
    assert_equal entity.data[:policies][0], @policies

    @client.delete_entity(@entity_name)
    entity =  @client.read_entity(@entity_name)
    assert_nil entity

  end

  test "#entity_alias" do
    err = assert_raises RuntimeError do
      @client.read_entity_alias(@entity_name, @alias_name)
    end
    assert_match /no such entity/, err.message

    @client.put_entity(@entity_name, @policies)
    err = assert_raises RuntimeError do
      @client.read_entity_alias(@entity_name, @alias_name)
    end
    assert_match /no such alias/, err.message

    auth_method = "token"
    @client.put_entity_alias(@entity_name, @alias_name, auth_method)
    entity_alias =  @client.read_entity_alias(@entity_name, @alias_name)
    assert_equal entity_alias.data[:mount_type], auth_method

    assert_equal @client.delete_entity_alias(@entity_name, @alias_name), true

    err = assert_raises RuntimeError do
      @client.delete_entity_alias(@entity_name, @alias_name)
    end
    assert_match /no such alias/, err.message
  end

  private

  def vault_client
    ::Vault::Client.new(
          address: vault_addr,
          token: Rails.configuration.astral[:vault_token]
    )
  end

  def vault_addr
    Rails.configuration.astral[:vault_addr]
  end
end
