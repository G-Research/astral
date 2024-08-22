module Services
  class AuthService
    def initialize
      # TODO make this selectable
      @impl = AppRegistryService.new
    end

    def authenticate!(token)
      @impl.authenticate!(token)
    end

    def authorize!(token, cert_issue_req)
      @impl.authorize!(token, cert_issue_req)
    end
  end
end
