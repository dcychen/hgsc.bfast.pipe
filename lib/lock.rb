#!/usr/bin/ruby
#
#

module Lock

  def self.remove_lock_file(file)
    FileUtils.rm(file)
  end

  def self.create_lock_file(file)
    File.open(file, "w") do |f|
      f.puts(Time.now)
    end
  end
end
