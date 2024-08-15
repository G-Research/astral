class CertificatesController < ApplicationController
  def create
    name = params[:common_name] || "host.example.com"
    ttl = params[:ttl] || "24h"
    cert = Services::VaultService.new.new_cert(name, ttl)
    render json: cert
  end
end
