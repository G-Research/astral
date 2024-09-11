module Services
  class DomainOwnershipService
    attr_reader :client

    def initialize
      @client = Faraday.new(ssl: ssl_opts, url: Rails.configuration.astral[:app_registry_addr]) do |faraday|
        faraday.request :authorization, "Bearer", -> { Rails.configuration.astral[:app_registry_token] }
        faraday.request :retry, retry_opts
        faraday.response :json
        faraday.response :raise_error, include_request: true
      end
    end

    def get_domain_info(fqdn)
      rslt = client.get("/api/v1beta1/domain-names/#{fqdn}").body
      convert(rslt)
    rescue Faraday::ResourceNotFound => e
      nil
    end

    private

    def convert(domain_info)
      if !domain_info || domain_info["isDeleted"]
        return nil
      end

      OpenStruct.new(
        fqdn: domain_info["fullyQualifiedDomainName"],
        group_delegation: domain_info["ownerDelegatedRequestsToTeam"],
        groups: domain_info["autoApprovedGroups"],
        users: domain_info["autoApprovedServiceAccounts"]
      )
    end

    def ssl_opts
      {
        ca_file: Rails.configuration.astral[:app_registry_ca_file],
        client_cert: Rails.configuration.astral[:app_registry_client_cert],
        client_key: Rails.configuration.astral[:app_registry_client_key]
      }
    end

    def retry_opts
      {
        max: 3,
        interval: 0.05,
        interval_randomness: 0.5,
        backoff_factor: 2
      }
    end
  end
end
