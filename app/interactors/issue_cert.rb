class IssueCert
  include Interactor::Organizer

  organize CheckPolicy, ObtainCert
end
