module Services
  class CertificateService
    def initialize
      # this should select an implementation service based on config
      @impl = VaultService.new
    end

    def new_cert(common_name, ttl)
      @impl.new_cert(common_name, ttl)
    end
  end
end
