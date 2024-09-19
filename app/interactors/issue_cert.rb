class IssueCert
  include Interactor::Organizer

  organize RefreshDomain, AuthorizeCertRequest, ObtainCert
end
