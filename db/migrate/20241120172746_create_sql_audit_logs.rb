class CreateSqlAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :sql_audit_logs do |t|
      t.string :request_id
      t.string :action
      t.string :result
      t.string :error
      t.string :subject
      t.string :cert_common_name
      t.string :kv_path

      t.timestamps
    end
  end
end
