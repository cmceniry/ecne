class AddPasswordCategory < ActiveRecord::Migration
  def self.up
    add_column :passwords, :category_id, :integer
  end

  def self.down
    remove_column :passwords, :category_id
  end
end
