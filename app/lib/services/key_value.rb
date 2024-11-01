module Services
  class KeyValue
    class << self
      def read(identity, path)
        impl.kv_read(identity, path)
      end

      def write(identity, path, data)
        impl.kv_write(path, data)
      end

      def delete(identity, path)
        impl.kv_delete(path)
      end

      private

      def impl
        # TODO this should select an implementation service based on config
        Clients::Vault
      end
    end
  end
end
