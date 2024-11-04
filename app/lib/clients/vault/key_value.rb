module Clients
  class Vault
    module KeyValue
      extend Policy

      def kv_read(identity, path)
        verify_policy(identity, policy_path(path))
        client.kv(kv_mount).read(path)
      end

      def kv_write(identity, path, data)
        create_kv_policy(path)
        assign_policy(identity, policy_path(path))
        client.logical.write("#{kv_mount}/data/#{path}", data: data)
      end

      def kv_delete(identity, path)
        verify_policy(identity, policy_path(path))
        client.logical.delete("#{kv_mount}/data/#{path}")
      end

      def configure_kv
        unless client.sys.mounts.key?(kv_mount.to_sym)
          enable_engine(kv_mount, kv_engine_type)
        end
      end

      private

      def kv_mount
        "kv_astral"
      end

      def kv_engine_type
        "kv-v2"
      end

      def create_kv_policy(path)
        client.sys.put_policy(policy_path(path), kv_policy(path))
      end

      def policy_path(path)
        "kv_policy/#{path}"
      end

      def kv_policy(path)
        policy = <<-EOH
               path "#{path}" {
                 capabilities = ["create", "read", "update", "delete"]
               }
        EOH
      end
    end
  end
end
