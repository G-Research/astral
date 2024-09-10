module Services
  class DomainOwnershipService
    attr_reader :client

    def initialize
      @client = Faraday.new(url: Rails.configuration.astral[:app_registry_uri]) do |faraday|
        faraday.response :raise_error, include_request: true
      end
    end

    def get_domain_info
    end

    private

    def convert(input)
      if !input || input["isDeleted"]
        return nil
      end

      OpenStruct.new(
               fqdn: domain_info["fullyQualifiedDomainName"],
               group_delegation: domain_info["ownerDelegatedRequestsToTeam"],
               groups: domain_info["autoApprovedGroups"],
               users: domain_info["autoApprovedServiceAccounts"]
             )
    end
  end
end
