class ApplicationController < ActionController::API
  before_action :set_default_format
  rescue_from StandardError, with: :handle_standard_error
  rescue_from AuthError, with: :handle_auth_error
  rescue_from BadRequestError, with: :handle_bad_request_error
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request

  attr_reader :identity # decoded and verified JWT

  def authenticate_request
    result = AuthenticateIdentity.call(request: request)
    if result.success?
      @identity = result.identity
    else
      raise AuthError.new result.message
    end
  end

  private

  def set_default_format
    request.format = :json
  end

  def handle_standard_error(exception)
    render json: { error: exception.message }, status: :internal_server_error
  end

  def handle_auth_error(exception)
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def handle_bad_request_error(exception)
    render json: { error: exception.message }, status: :bad_request
  end

end
