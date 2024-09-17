class SecretsController < ApplicationController
  before_action :authenticate_request

  def create
    req = Requests::CreateSecretRequest.new(params_permitted)
    if !req.valid?
      raise BadRequestError.new req.errors.full_messages
    end
    result = CreateSecret.call(request: req, identity: identity)
    if result.failure?
      raise (result.error || StandardError.new(result.message))
    end
    @secret = result.secret
  end

  private

  def params_permitted
    attrs = Requests::CreateSecretRequest.attributes.keys
    params.require(:secret_request).permit(attrs)
  end
end
