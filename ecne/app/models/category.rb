class Category < ActiveRecord::Base
  has_many :passwords
  
  validates_uniqueness_of :name
end
