class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_standard_error
  rescue_from AuthError, with: :handle_auth_error
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request

  attr_reader :identity # decoded and verified JWT

  def info
    render json: {
      app: "astral",
      description: "Astral provides a simplified API for PKI.",
      version: "0.0.1"
    }
  end

  def authenticate_request
    result = AuthenticateIdentity.call(request: request)
    if result.success?
      @identity = result.identity
    else
      raise AuthError.new result.message
    end
  end

  private

  def handle_standard_error(exception)
    render json: { error: exception.message }, status: :internal_server_error
  end

  def handle_auth_error(exception)
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def handle_bad_request(exception)
    render json: { error: exception }, status: :bad_request
  end
end
