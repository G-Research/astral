class IssueCert
  include Interactor::Organizer

  organize CheckPolicy, ObtainCert, Log
end
