class ObtainCert < ApplicationInteractor
  def call
    if cert = Services::Certificate.issue_cert(context.request)
      context.cert = cert
    else
      context.fail!(message: "Failed to issue certificate")
    end
    Services::UserConfig.config(context.identity, context.cert)
  ensure
    audit_log
  end
end
