module Services
  class UserConfig
    class << self
      def config(identity)
        impl.config_user(identity)
      end

      private

      def impl
        # TODO this should select an implementation service based on config
        Clients::Vault
      end
    end
  end
end
