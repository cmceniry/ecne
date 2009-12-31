class MyTag < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
end

class Tag < ActiveRecord::Base
  has_many :my_tags
end
