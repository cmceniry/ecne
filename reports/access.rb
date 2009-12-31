#
# To run me make sure you run the setup first:
#
# /usr/local/app/ecne/setup.sh 
#
# Then collect the message logs with
#
# zcat /var/log/messages.old/*.gz | cat - /var/log/messages > /tmp/todo
#
# And then run me with:
#
# /usr/local/app/ecne/ecne/script/runner /usr/local/app/ecne/reports/access.rb
#
# Change the last line to do what you want it to.

require 'zlib'
require 'time'
require 'pp'

def get_accesses(username)
  # Gets when user last accessed a password from the log compilation from /tmp/todo
  ret = {}

  ##logs = Dir.open("/var/log/messages.old").entries.select { |l| l =~ /^messages.*gz/ }
  ##logs = logs.map do |logfile|
    ##[ File.stat("/var/log/messages.old/#{logfile}").mtime.to_i, logfile ]
  ##end
  ##logs.sort.each do |l|
    ###Zlib::Deflate.deflate(File.read("/var/log/messages.old/#{l[1]}")).split("\n").each do |line|
      ###puts line
    ###end
  ##end
  logs = File.read("/tmp/todo").split("\n").select { |l| l =~ / ecne\[\d+\]: #{username}\(/ }
  logs.each do |l|
    ls = l.split
    time = Time.parse(ls[0..2].join(" "))
    if [ "edit", "view" ].include?(ls[6])
      next if ls[8].to_i.to_s != ls[8]
      ret[ls[8].to_i] = time if ret[ls[8].to_i].nil? or ret[ls[8].to_i] < time
    end
  end

  return ret
end

def find_dirty(accesses)
  # Finds which passwords were accessed after being changed
  ret = []
  accesses.keys.sort.each do |id|
    pw = Password.find(id)
    if pw.lastchanged < accesses[id]
      ret << pw
    end
  end
  return ret
end

def mark_dirty(passwords, tag)
  # Adds a tag to a list of passwords
  passwords.each do |pw|
    pw.tags << Tag.get(tag)
    pw.save
  end
end

#mark_dirty(find_dirty(get_accesses("mwong")), "audit:mwong:term")
