class AddMyTags < ActiveRecord::Migration
  def self.up
    create_table :my_tags do |t|
      t.column :user_id, :integer
      t.column :tag_id, :integer
    end
  end

  def self.down
    drop_table :my_tags
  end
end
