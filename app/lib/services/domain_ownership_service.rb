module Services
  class DomainOwnershipService
    class << self
      def get_domain_info(fqdn)
        impl.get_domain_info(fqdn)
      end

      private

      def impl
        # TODO this should select an implementation service based on config
        AppRegistryService
      end
    end
  end
end
