require "test_helper"

class VaultTest < ActiveSupport::TestCase
  attr_reader :intermediate_ca_mount
  attr_reader :root_ca_mount
  attr_reader :kv_mount

  setup do
    @client = Clients::Vault
    @token = Clients::Vault.token
    Clients::Vault.token = vault_token
    @root_ca_mount = SecureRandom.hex(4)
    @intermediate_ca_mount = SecureRandom.hex(4)
    @kv_mount = SecureRandom.hex(4)
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
    assert_instance_of Vault::Secret, @client.kv_write("testing/secret", { password: "sicr3t" })
  end

  private

  def vault_client
    ::Vault::Client.new(
          address: vault_addr,
          token: vault_token
    )
  end

  def vault_addr
    Rails.configuration.astral[:vault_addr]
  end

  def vault_token
    Rails.configuration.astral[:vault_token]
  end
end
