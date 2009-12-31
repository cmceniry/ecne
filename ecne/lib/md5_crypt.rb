#!/usr/bin/env ruby

# 29/03/2005 Version 0.1 


# based on http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/325204/index_txt
# which is based on FreeBSD src/lib/libcrypt/crypt.c 1.2
# http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/src/lib/libcrypt/crypt.c?rev=1.2&content-type=text/plain

# Original license:
# * "THE BEER-WARE LICENSE" (Revision 42):
# * <phk@login.dknet.dk> wrote this file.  As long as you retain this notice you
# * can do whatever you want with this stuff. If we meet some day, and you think
# * this stuff is worth it, you can buy me a beer in return.   Poul-Henning Kamp

# This port adds no further stipulations.  I forfeit any copyright interest.

require "digest/md5"

def md5crypt(password, salt, magic='$1$')
  
  # /* The password first, since that is what is most unknown */ /* Then our magic string */ /* Then the raw salt */
  m = Digest::MD5.new
  m.update(password + magic + salt)

  # /* Then just as many characters of the MD5(pw,salt,pw) */
  mixin = Digest::MD5.new.update(password + salt + password).digest
  password.length.times do |i|
    m.update(mixin[i % 16].chr)
  end

  # /* Then something really weird... */
  # Also really broken, as far as I can tell.  -m
  i = password.length
  while i != 0
    if (i & 1) != 0
      m.update("\x00")
    else
      m.update(password[0].chr)
    end
    i >>= 1
  end

  final = m.digest

  # /* and now, just to make sure things don't run too fast */
  1000.times do |i|
    m2 = Digest::MD5.new

    if (i & 1) != 0 
      m2.update(password) 
    else
      m2.update(final)
    end

    if (i % 3) != 0 
      m2.update(salt)
    end
    if (i % 7) != 0 
      m2.update(password) 
    end
    
    if (i & 1) != 0 
      m2.update(final) 
    else
      m2.update(password)
    end

    final = m2.digest
  end

  # This is the bit that uses to64() in the original code.

  itoa64 = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

  rearranged = ""

  [ [0, 6, 12], [1, 7, 13], [2, 8, 14], [3, 9, 15], [4, 10, 5] ].each do |a, b, c|

    v = final[a] << 16 | final[b] << 8 | final[c]

    4.times do
      rearranged += itoa64[v & 0x3f].chr
      v >>= 6 
    end
  end

  v = final[11]

  2.times do
    rearranged += itoa64[v & 0x3f].chr
    v >>= 6
  end
  magic + salt + '$' + rearranged
end

if $0 == __FILE__
  def mytest(clear_password, the_hash)
    magic, salt = the_hash.split('$')[1,2]
    magic = '$' + magic + '$'
    md5crypt(clear_password, salt, magic) == the_hash
  end
  
  test_array = 
    if ARGV.empty? 
      [ [' ', '$1$yiiZbNIH$YiCsHZjcTkYd31wkgW8JF.'],
        ['pass', '$1$YeNsbWdH$wvOF8JdqsoiLix754LTW90'],
        ['____fifteen____', '$1$s9lUWACI$Kk1jtIVVdmT01p0z3b/hw1'],
        ['____sixteen_____', '$1$dL3xbVZI$kkgqhCanLdxODGq14g/tW1'],
        ['____seventeen____', '$1$NaH5na7J$j7y8Iss0hcRbu3kzoJs5V.'],
        ['__________thirty-three___________', '$1$HO7Q6vzJ$yGwp2wbL5D7eOVzOmxpsy.'],
        ['apache', '$apr1$J.w5a/..$IW9y6DR0oO/ADuhlMF5/X1']
      ] 
    else
      [ [ARGV[0], ARGV[1]] ]
    end

  test_array.each do |clearpw, hashpw|
    status = mytest(clearpw, hashpw) ? "OK" : "FAIL"
    puts("testing '#{clearpw}' against '#{hashpw}' #{status}")
  end
end
