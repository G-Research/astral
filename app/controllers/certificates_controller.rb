class CertificatesController < ApplicationController
  before_action :authenticate_request

  def create
    req = CertIssueRequest.new(params_permitted)
    if !req.valid?
      render json: { error: req.errors }, status: :bad_request
    end
    result = IssueCert.call(request: req)
    if result.success?
      render json: result.cert
    else
      raise StandardError.new result.message
    end
  end

  private

  def params_permitted
    attrs = %i[ common_name
                alt_names
                exclude_cn_from_sans
                format
                not_after
                other_sans
                private_key_format
                remove_roots_from_chain
                ttl
                uri_sans
                ip_sans
                serial_number
                client_flag
                code_signing_flag
                email_protection_flag
                server_flag
              ]
    params.permit(attrs)
  end
end
