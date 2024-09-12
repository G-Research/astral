module Services
  class DomainOwnershipService
    attr_reader :impl

    def initialize
      # TODO this should select an implementation service based on config
      @impl = AppRegistryService.new
    end

    def get_domain_info(fqdn)
      impl.get_domain_info(fqdn)
    end
  end
end
