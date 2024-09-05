class IssueCert
  include Interactor::Organizer

  organize AuthorizeRequest, ObtainCert, Log
end
