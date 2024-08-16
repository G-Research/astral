class CertificatesController < ApplicationController
  before_action :authenticate_request

  def create
    name = params[:common_name] || "host.example.com"
    ttl = params[:ttl] || "24h"
    cert = Services::CertificateService.new.get_cert(name, ttl)
    render json: cert
  end
end
