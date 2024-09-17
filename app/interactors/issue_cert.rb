class IssueCert
  include Interactor::Organizer
  include FailOnError

  organize RefreshDomain, AuthorizeRequest, ObtainCert
end
