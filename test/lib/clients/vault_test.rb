require "test_helper"

class VaultTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
  end

  test "#configure_kv" do
    random_mount = SecureRandom.hex(4)
    @client.stub :kv_mount, random_mount do
      assert_not_nil @client.configure_kv
      engines = vault_client.sys.mounts
      assert_equal "kv", engines[random_mount.to_sym].type
    end
  end

  private

  def vault_client
    ::Vault::Client.new(
          address: Rails.configuration.astral[:vault_addr],
          token: Rails.configuration.astral[:vault_token]
    )
  end
end
