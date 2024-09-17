class SecretsController < ApplicationController
  before_action :authenticate_request

  def create
    req = Requests::SecretRequest.new(params_permitted)
    if !req.valid?
      raise BadRequestError.new req.errors.full_messages
    end
    result = WriteSecret.call(request: req, identity: identity)
    if result.failure?
      raise (result.error || StandardError.new(result.message))
    end
    @secret = result.secret
  end

  def show
    req = Requests::SecretRequest.new(path: params.require(:path))
    if !req.valid?
      raise BadRequestError.new req.errors.full_messages
    end
    result = ReadSecret.call(request: req, identity: identity)
    if result.failure?
      raise (result.error || StandardError.new(result.message))
    end
    @secret = result.secret
  end
  
  private

  def params_permitted
    params.require(:secret_request).permit(:path, data: {})
  end
end
