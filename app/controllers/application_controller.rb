class ApplicationController < ActionController::API
  def info
    render json: {
      app: "astral",
      description: "Astral provides a simplified API for PKI.",
      version: "0.0.1"
    }
  end
end
