class Password < ActiveRecord::Base
  acts_as_taggable
  has_many :password_entries
  validates_presence_of :accountname, :contextname, :category_id
  belongs_to :category

  def validate
    p = Password.find_by_accountname_and_contextname(accountname, contextname)
    errors.add_to_base("Accountname/contextname are not distinct") unless
      p.nil? or p.id == id
  end
  
  def name
    "" + (category.nil? ? 'UNKNOWN' : category.name ) + " | " +
         (contextname.nil? ? 'UNKNOWN' : contextname ) + " | " +
         accountname
  end
  
  def current
    PasswordEntry.find(:first, :conditions => ["password_id = #{id}", "cdate = max(cdate)"], :order => "cdate DESC")
  end
  
  def value
    current.nil? ? "notset" : current.value
  end
  
  def lastchanged
    current.nil? ? "notset" : current.cdate
  end
  
  def lastchangedby
    current.nil? ? "notset" : current.cwho
  end
  
  def allvalues
    PasswordEntry.find(:all, :conditions => ["password_id = #{id}"], :order => :cdate).map { |pe| pe.value }
  end
  
  def newvalue
    ""
  end
  
  def newvalue=(value)
    @modifier ||= "UNKNOWN"
    a = PasswordEntry.new(:value => value, :password_id => id, :cdate => Time.now, :cwho => @modifier )
    a.save
  end

  def permissions
    tags.select { |t| t.name =~ /^[rw]:[ug]:\S+$/ }.map { |t| t.name.split(":",3) }
  end
  
  def can?(action, user)
    groups = Ecne::groups[user] || []
    return true if groups.include?('pwzar')
    success = permissions.find do |p|
      (action.include?(p[0])) && ((p[1] == "u" && p[2] == user) || (p[1] == "g" && groups.include?(p[2])))
    end
    !success.nil?
  end

  def modifier=(who)
    @modifier = who
  end
  
  # Class functions #
  
  def Password::search(search_text = "", active = "1")
    active_s = active == "1" ? "active = 1" : "1 = 1"
    if search_text.empty?
      return find(:all, :conditions => [ active_s ])
    end
    pw_from_accountname = Password.find(:all,
                                        :conditions => [ "accountname like ? AND #{active_s}",
                                                         "%" + search_text + "%" ])
    pw_from_contextname = Password.find(:all,
                                        :conditions => [ "contextname like ? AND #{active_s}",
                                                         "%" + search_text + "%" ])
    tags = Tag.find(:all,
                    :conditions => [ "name like ? ",
                                     "%" + search_text + "%" ]).map { |t| t.id }
    taggings = Tagging.find(:all,
                            :conditions => [ "taggable_type = ? AND  tag_id IN (?)",
                                             "0",
                                             tags ]).map { |tg| tg.taggable_id }
    pw_from_tags = Password.find(:all,
                                 :conditions => [ "#{active_s} AND id IN (?)",
                                                  taggings ])
    
    return (pw_from_accountname + pw_from_contextname + pw_from_tags).uniq
  end

  def Password::search_ids(search_text = "")
    search(search_text).map { |p| p.id }
  end
  
end

class Tag < ActiveRecord::Base
  def Tag::get(value)
    t = find_by_name(value)
    if t.nil?
      t = new(:name => value)
      t.save
    end
    t
  end
end
