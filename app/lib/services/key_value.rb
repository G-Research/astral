module Services
  class KeyValue
    class << self
      def read(path)
        impl.kv_read(path)
      end

      def write(path, data)
        impl.kv_write(path, data)
      end

      def delete(path)
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
