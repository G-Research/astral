class IssueCert
  include Interactor::Organizer
  include FailOnError

  organize RefreshDomain, AuthorizeCertRequest, ObtainCert
end
