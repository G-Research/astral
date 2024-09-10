class CreateDomains < ActiveRecord::Migration[7.2]
  def change
    create_table :domains do |t|
      t.string :fqdn, null: false
      t.text :users
      t.text :groups
      t.boolean :group_delegation, default: false
      t.timestamps
      t.index :fqdn, unique: true
    end
  end
end
