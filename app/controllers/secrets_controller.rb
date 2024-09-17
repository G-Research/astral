class SecretsController < ApplicationController
  before_action :authenticate_request

  def create
    req = CertIssueRequest.new(params_permitted)
    if !req.valid?
      raise BadRequestError.new req.errors.full_messages
    end
    result = IssueCert.call(request: req, identity: identity)
    if result.failure?
      raise (result.error || StandardError.new(result.message))
    end
    @cert = result.cert
  end

  private

  def params_permitted
    attrs = CertIssueRequest.new.attributes.keys
    params.require(:secret_request).permit(attrs)
  end
end
