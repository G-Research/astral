class ObtainCert < ApplicationInteractor
  def call
    if cert = Services::Certificate.issue_cert(context.identity, context.request)
      context.cert = cert
    else
      context.fail!(message: "Failed to issue certificate")
    end
  ensure
    audit_log
  end
end
