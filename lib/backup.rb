#!/usr/bin/ruby
#
#

$:.unshift File.join(File.dirname(__FILE__))
require 'lock'
require 'fileutils'

module Backup
  # send the transferred raw data path to backup file
  def self.backup_data(file, path)
    dir = File.dirname(path)
    if !File.directory?(dir)
      FileUtils.mkdir_p(dir)
    end
    lock = "#{file}.lock"
    temp = "#{file}.tmp"
    if File.exist?(lock)
      add_line_to_file(temp, path)
    else
#      create_lock_file(lock)
      Lock::create_lock_file(lock)
      if File.exist?(temp)
        File.open(temp).readline do |r|
          add_line_to_file(file, r)
        end
        FileUtils.rm temp
      end
      add_line_to_file(file, path)
      Lock::remove_lock_file(lock)
    end
  end
  
  private
  # append the input to the end of the file
  def self.add_line_to_file(file, line)
    File.open(file, "a") {|f| f.puts("#{line}")}
  end
end
