class ObtainCert < ApplicationInteractor
  def call
    if cert = Services::SecretsService.issue_cert(context.request)
      context.cert = cert
    else
      context.fail!(message: "Failed to issue certificate")
    end
  ensure
    audit_log
  end
end
