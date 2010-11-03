#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# This class parses the machine names and the email addresses
# and passes it to the appropriate methods to output the disk
# usage.
#
# Author: Phillip Coleman

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/se_inst.rb"

class Transfer_disk_usage
  def initialize
  end

  def run(params)
    disk_usage(params[:m_name], params[:e_addr])
  end
  
  private
  
  def disk_usage(machine_names, email_addr)
    Helpers::log("Invalid or misssing machine name", 1) if machine_names.nil?

    machine_names.each do |key, value|
      temp_se = Se_inst.new(value, 1)
      puts temp_se.check_storage(email_addr)
    end
  end
end

