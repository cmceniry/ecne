class ChangePasswordName < ActiveRecord::Migration
  def self.up
    rename_column :passwords, :name, :accountname
    add_column    :passwords, :contextname, :string
  end

  def self.down
    remove_column :passwords, :contextname
    rename_column :passwords, :accountname, :name
  end
end
