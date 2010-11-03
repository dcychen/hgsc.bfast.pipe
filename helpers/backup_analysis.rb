#!/usr/bin/ruby
#
# grabs all of the analysis directories completed from the previous month
# and place them into the backup file
# 
# Author: David Chen

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'time_helpers'
require 'find'
require 'backup'

def valid?(run_name)
  valid_prefix = false
  valid_suffix = false

  if run_name.match(/^\d+_\d+_\d+_SP_/) ||
     run_name.match(/^\d+_\d+_\d+_SL_/)
    valid_prefix = true
  end

  if run_name.match(/p\w_\d+_\d$/) ||
     run_name.match(/s\w_\d+_\d$/) ||
     run_name.match(/s\w_\d+_\d_BC\d+$/) ||
     run_name.match(/s\w_\d+_\d_bc\d+$/)
    valid_suffix = true
  end
  return valid_prefix && valid_suffix
end

backup_file = "#{ENV['HOME']}/.hgsc_solid/backup/" +
              "solid_analysis_backup.txt"
paths = ARGV[0].split
last_month = TimeHelpers::get_pre_mon
year = last_month.split("-")[0]
month = last_month.split("-")[1]

paths.each do |d|
  Find.find(d) do |p| 
  if /#{year}\/#{month}\//.match(p) && valid?(p.split("/")[-1])
    Backup::backup_data(backup_file, p) 
    end
  end
end
