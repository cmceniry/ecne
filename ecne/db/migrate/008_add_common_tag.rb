class AddCommonTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :common, :boolean, :default => false
    Tag.find(:all).each { |tag| tag.common = false; tag.save }
  end

  def self.down
    remove_column :tags, :common
  end
end
