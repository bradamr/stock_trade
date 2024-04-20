require 'base64'
require 'io/console'

require_relative '../models/security/credentials'
require_relative '../models/security/encryption'

class FileEncryption
  def self.encrypt(file_path)
    results = Encryption.new.encrypt(File.read(file_path))
    File.write(file_path + '.enc', results[:value])

    iv_base = Base64.encode64(results[:credentials].iv).chomp
    salt_base = Base64.encode64(results[:credentials].salt).chomp

    puts "IV: #{iv_base}\nSalt: #{salt_base}"
  end

  def self.decrypt(file_path)
    results = Encryption.new.decrypt(File.read(file_path))
    File.write(file_path + '.unenc', results[:value])
  end
end

def prompt(title, new_line = false)
  print "\n" if new_line
  print "Please enter #{title}: "
end

prompt("File path")
file_path = gets.chomp

FileEncryption.encrypt(file_path)
#FileEncryption.decrypt(file_path)
