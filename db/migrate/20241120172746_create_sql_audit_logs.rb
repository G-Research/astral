class CreateSqlAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :sql_audit_logs do |t|
      t.string :request_id, null: false
      t.string :action, null: false
      t.string :result, null: false
      t.string :error, null: true
      t.string :subject, null: false
      t.string :cert_common_name, null: true
      t.string :kv_path, null: true
      t.timestamps
    end
    add_index :sql_audit_logs, [ :subject, :created_at ]
  end
end
