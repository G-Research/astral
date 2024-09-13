class ObtainCert
  include Interactor
  include FailOnError

  def call
    if cert = Services::CertificateService.issue_cert(context.request)
      context.cert = cert
    else
      context.fail!(message: "Failed to issue certificate")
    end
  end
end
