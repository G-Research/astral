class CreateKvMetadata < ActiveRecord::Migration[7.2]
  def change
    create_table :kv_metadata do |t|
      t.string :path, null: false, index: { unique: true }
      t.string :owner, null: false
      t.string :read_groups, null: true
      t.string :write_groups, null: true
      t.timestamps
    end
  end
end
