class IssueCert
  include Interactor::Organizer

  organize AuthenticateRequest, ObtainCert, Log
end
