class IssueCert
  include Interactor::Organizer
  include FailOnError

  organize RefreshDomain, AuthorizeRequest, ObtainCert, Log
end
