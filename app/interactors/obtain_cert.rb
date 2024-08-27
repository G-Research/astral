class ObtainCert
  include Interactor

  def call
    context.cert = Services::CertificateService.new.issue_cert(context.request)
  end
end
