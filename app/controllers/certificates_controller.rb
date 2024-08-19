class CertificatesController < ApplicationController
  before_action :authenticate_request

  def create
    cert = Services::CertificateService.new.get_cert_for identity
    render json: cert
  end
end
