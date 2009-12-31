#!/usr/bin/env ruby
RAILS_ROOT="/usr/local/app/ecne/ecne"
require RAILS_ROOT + '/config/boot'
require RAILS_ROOT + '/config/environment'

current_time = Time.now.to_i

passwords = Password.find(:all, :conditions => [ 'active = 1' ]).map do |pw|
  [pw.name, pw.lastchanged, pw.tags.map { |t| t.name }]
end

passwords.reject! do |pw|
  (pw[2].include?("neverexpires") || pw[2].include?("sshkey")) && (not pw[2].any? { |t| t =~ /^audit/ })
end

entries = {}
total_passwords    = 0
total_audittags    = 0
total_auditclaimed = 0

puts "--------------------- Summary ---------------------"
puts "                   total\taudit\tclaimed"
[7,30,60,90,120,180,360].each do |tf|
  t = Time.at(current_time - tf*24*60*60)
  pws = passwords.select { |pw| pw[1] > t }
  printf("  < %3d days old =  %4d\t %4d\t     %4d\n",
         tf,
         pws.size,
         pws.select { |pw| pw[2].any? { |tag| tag =~ /^audit/ } }.size,
         pws.select { |pw| pw[2].any? { |tag| tag =~ /^audit-/ } }.size
        )
  total_passwords     += pws.size
  total_audittags     += pws.select { |pw| pw[2].any? { |tag| tag =~ /^audit/ } }.size
  total_auditclaimed  += pws.select { |pw| pw[2].any? { |tag| tag =~ /^audit-/ } }.size
  passwords = passwords.reject { |pw| pw[1] > t }
  entries[tf] = pws.map { |pw| [pw[0], pw[1], pw[2].any? { |tag| tag =~ /^audit/ }, pw[2].any? { |tag| tag =~ /^audit-/ } ] }
end
pws = passwords
printf(" >= 360 days old =  %4d\t %4d\t     %4d\n",
       passwords.size,
       passwords.select { |pw| pw[2].any? { |tag| tag =~ /^audit/ } }.size,
       passwords.select { |pw| pw[2].any? { |tag| tag =~ /^audit-/ } }.size
      )
entries[-1] = pws.map { |pw| [pw[0], pw[1], pw[2].any? { |tag| tag =~ /^audit/ }, pw[2].any? { |tag| tag =~ /^audit-/ } ] }
total_passwords     += pws.size
total_audittags     += pws.select { |pw| pw[2].any? { |tag| tag =~ /^audit/ } }.size
total_auditclaimed  += pws.select { |pw| pw[2].any? { |tag| tag =~ /^audit-/ } }.size
printf("                   -----\t-----\t---------\n")
printf("          totals =  %4d\t %4d\t     %4d\n", total_passwords, total_audittags, total_auditclaimed)
puts
puts "# : has been claimed"
puts "* : has audit tag"
puts

[7,30,60,90,120,180,360,-1].each do |tf|
  if tf == -1
    printf( "---------------- >= 360 days old ------------------\n" )
  else
    printf( "----------------  < %3d days old ------------------\n", tf )
  end
  puts entries[tf].select { |pw| tf > 90 or tf == -1 or pw[2] }.sort { |pwa,pwb| pwa[0] <=> pwb[0] }.map { |pw| (pw[3] ? "#" : " " ) + (pw[2] ? "* " : "  ") + pw[0] }.join("\n")
  puts
  puts
end
