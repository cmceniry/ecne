class CreatePasswordEntries < ActiveRecord::Migration
  def self.up
    create_table :password_entries do |t|
      t.column :password_id, :integer
      t.column :value,       :text
      t.column :cdate,       :timestamp
      t.column :cwho,        :string
    end
  end

  def self.down
    drop_table :password_entries
  end
end
