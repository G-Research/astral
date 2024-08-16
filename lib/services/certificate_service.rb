module Services
  class CertificateService
    def initialize
      # this should select an implementation service based on config
      @impl = VaultService.new
    end

    def get_cert(common_name, ttl)
      @impl.get_cert(common_name, ttl)
    end
  end
end
