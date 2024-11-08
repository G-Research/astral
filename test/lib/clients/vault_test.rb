require "test_helper"

class VaultTest < ActiveSupport::TestCase
  attr_reader :intermediate_ca_mount
  attr_reader :root_ca_mount
  attr_reader :kv_mount
  attr_reader :policies
  attr_reader :entity_name
  attr_reader :alias_name

  setup do
    @client = Clients::Vault
    @token = Clients::Vault.token
    Clients::Vault.token = vault_token
    @root_ca_mount = SecureRandom.hex(4)
    @intermediate_ca_mount = SecureRandom.hex(4)
    @kv_mount = SecureRandom.hex(4)
    @policies = SecureRandom.hex(4)
    @entity_name = SecureRandom.hex(4)
    @alias_name = SecureRandom.hex(4)
    @identity = Identity.new
    @identity.sub = SecureRandom.hex(4)
  end

  teardown do
    Clients::Vault.token = @token
    vault_client.sys.unmount(root_ca_mount)
    vault_client.sys.unmount(intermediate_ca_mount)
  end

  test ".configure_kv" do
    @client.stub :kv_mount, kv_mount do
      assert @client.configure_kv
      engines = vault_client.sys.mounts
      assert_equal "kv", engines[kv_mount.to_sym].type
    end
  end

  test ".configure_pki" do
    @client.stub :root_ca_mount, root_ca_mount do
      @client.stub :intermediate_ca_mount, intermediate_ca_mount do
        assert @client.configure_pki

        [ root_ca_mount, intermediate_ca_mount ].each do |mount|
          engines = vault_client.sys.mounts
          assert_equal "pki", engines[mount.to_sym].type

          read_cert = vault_client.logical.read("#{mount}/cert/ca").data[:certificate]
          assert_match "BEGIN CERTIFICATE", read_cert

          cluster_config = vault_client.logical.read("#{mount}/config/cluster").data
          assert_equal "#{vault_addr}/v1/#{mount}", cluster_config[:path]
          assert_equal "#{vault_addr}/v1/#{mount}", cluster_config[:aia_path]
        end

        role_config = vault_client.logical.read("#{intermediate_ca_mount}/roles/astral").data
        assert_not_nil role_config[:issuer_ref]
        assert_equal 720.hours, role_config[:max_ttl]
        assert_equal true, role_config[:allow_any_name]
      end
    end
  end

  test ".rotate_token" do
    # begins with default token
    assert_equal vault_token, @client.token
    assert @client.rotate_token
    # now has a new token
    assert_not_equal vault_token, @client.token
    # ensure we can write with the new token
    assert_instance_of Vault::Secret, @client.kv_write(@identity, "testing/secret", { password: "sicr3t" })
  end

  test "entity methods" do
    entity =  @client.read_entity(@entity_name)
    assert_nil entity

    @client.put_entity(@entity_name, @policies)
    entity =  @client.read_entity(@entity_name)
    assert_equal @policies, entity.data[:policies][0]

    @client.delete_entity(@entity_name)
    entity =  @client.read_entity(@entity_name)
    assert_nil entity
  end

  test "kv methods" do
    # check kv_write
    path = "test/path/#{SecureRandom.hex}"
    secret = @client.kv_write(@identity, path, { data: "data" })
    assert_kind_of Vault::Secret, secret

    # check kv_read
    read_secret = @client.kv_read(@identity, path)
    assert_kind_of Vault::Secret, read_secret

    # check policy is created
    entity = @client.read_entity(@identity.sub)
    assert_includes entity.data[:policies], "kv_policy/#{path}"

    # check kv_read denied to other identity
    alt_identity = Identity.new
    alt_identity.sub = SecureRandom.hex(4)
    err = assert_raises { @client.kv_read(alt_identity, path) }
    assert_kind_of AuthError, err

    # check kv_delete denied to other identity
    err = assert_raises { @client.kv_delete(alt_identity, path) }
    assert_kind_of AuthError, err

    # check kv_delete
    del_secret = @client.kv_delete(@identity, path)
    assert del_secret
    # check policy is removed
    entity = @client.read_entity(@identity.sub)
    assert_not_includes entity.data[:policies], "kv_policy/#{path}"
    err = assert_raises { @client.kv_read(@identity, path) }
    assert_kind_of AuthError, err
  end

  test "entity_alias methods" do
    # confirm no entity yet
    auth_path = "token"
    err = assert_raises RuntimeError do
      @client.read_entity_alias(@entity_name, @alias_name, auth_path)
    end
    assert_match /no such entity/, err.message

    # confirm no alias yet
    @client.put_entity(@entity_name, @policies)
    err = assert_raises RuntimeError do
      @client.read_entity_alias(@entity_name, @alias_name, auth_path)
    end
    assert_match /no such alias/, err.message

    # create alias
    @client.put_entity_alias(@entity_name, @alias_name, auth_path)
    entity_alias =  @client.read_entity_alias(@entity_name, @alias_name, auth_path)
    assert_equal auth_path, entity_alias.data[:mount_type]

    # confirm deleted alias
    assert_equal true, @client.delete_entity_alias(@entity_name, @alias_name, auth_path)
    err = assert_raises RuntimeError do
      @client.delete_entity_alias(@entity_name, @alias_name, auth_path)
    end
    assert_match /no such alias/, err.message
  end

  test ".assign_policy creates valid entity" do
    @client.assign_policy(@identity, "test_path")
    entity = @client.read_entity(@identity.sub)
    assert entity.data[:policies].any? { |p|
      p == "test_path" }
    assert entity.data[:aliases].any? { |a|
      a[:mount_type] == "oidc"  && a[:name] == @identity.sub }
  end

  private

  def vault_client
    ::Vault::Client.new(
          address: vault_addr,
          token: vault_token,
          ssl_ca_cert: ssl_cert,
          ssl_pem_file: ssl_client_cert,
          ssl_key_file: ssl_client_key
    )
  end

  def vault_addr
    Config[:vault_addr]
  end

  def vault_token
    Config[:vault_token]
  end

  def ssl_cert
    Config[:vault_ssl_cert]
  end

  def ssl_client_cert
    Config[:vault_ssl_client_cert]
  end

  def ssl_client_key
    Config[:vault_ssl_client_key]
  end
end
