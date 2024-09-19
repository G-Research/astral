module Services
  class DomainOwnership
    class << self
      def get_domain_info(fqdn)
        impl.get_domain_info(fqdn)
      end

      private

      def impl
        # TODO this should select an implementation service based on config
        Clients::AppRegistry
      end
    end
  end
end
