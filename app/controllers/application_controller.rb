class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_standard_error
  rescue_from AuthError, with: :handle_auth_error
  attr_reader :identity # decoded and verified JWT

  def info
    render json: {
      app: "astral",
      description: "Astral provides a simplified API for PKI.",
      version: "0.0.1"
    }
  end

  def authenticate_request
    token = request.headers["Authorization"]
    token = token.split(" ").last if token
    @identity = Services::AuthService.new.authenticate!(token)
  end

  private

  def handle_standard_error(exception)
    render json: { error: exception.message }, status: :internal_server_error
  end

  def handle_auth_error(exception)
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
