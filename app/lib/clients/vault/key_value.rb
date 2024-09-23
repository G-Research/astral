module Clients
  class Vault
    class << self
      def kv_read(path)
        client.kv(kv_mount).read(path)
      end

      def kv_write(path, data)
        unless client.sys.mounts.key?(kv_mount.to_sym)
          enable_engine(kv_mount, kv_engine_type)
        end
        client.logical.write("#{kv_mount}/data/#{path}", data: data)
      end

      def kv_delete(path)
        client.logical.delete("#{kv_mount}/data/#{path}")
      end

      private

      def kv_mount
        "kv_astral"
      end

      def kv_engine_type
        "kv-v2"
      end
    end
  end
end
