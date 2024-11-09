module Clients
  class Vault
    module KeyValue
      extend Policy

      def kv_read(identity, path)
        verify_policy(identity, producer_policy_path(path))
        client.kv(kv_mount).read(path)
      end

      def kv_write(identity, groups, path, data)
        create_kv_policies(path)
        assign_identity_policy(identity, producer_policy_path(path))
        assign_groups_policy(groups, consumer_policy_path(path))
        client.logical.write("#{kv_mount}/data/#{path}", data: data)
      end

      def kv_delete(identity, path)
        verify_policy(identity, producer_policy_path(path))
        client.logical.delete("#{kv_mount}/data/#{path}")
        remove_identity_policy(identity, producer_policy_path(path))
        remove_groups_policy(consumer_policy_path(path))
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

      def create_kv_policies(path)
        client.sys.put_policy(producer_policy_path(path), kv_producer_policy(path))
        client.sys.put_policy(consumer_policy_path(path), kv_consumer_policy(path))
      end

      def producer_policy_path(path)
        "kv_policy/#{path}/producer"
      end

      def consumer_policy_path(path)
        "kv_policy/#{path}/consumer"
      end

      def kv_producer_policy(path)
        policy = <<-EOH
               path "#{path}" {
                 capabilities = ["create", "read", "update", "delete"]
               }
        EOH
      end

      def kv_consumer_policy(path)
        policy = <<-EOH
               path "#{path}" {
                 capabilities = ["read"]
               }
        EOH
      end
    end
  end
end
