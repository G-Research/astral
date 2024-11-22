class AuditLog < ApplicationRecord
  validates :request_id, :action, :result, :subject, presence: true

  if Config[:db_encryption]
    encrypts :request_id, :action, :result, :error, :subject, :cert_common_name, :kv_path
  end
end
