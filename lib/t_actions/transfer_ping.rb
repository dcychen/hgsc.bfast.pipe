#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# The class parses a list of machines and then attempts to open
# up a ssh connection to them. If succesful it returns that
# the machine is active.
#
# Author: Phillip Coleman

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/ping.rb"

class Transfer_ping
  def initialize
  end

  def run(params)
    ping_servers(params[:m_name])
  end
  
  private
  
  def ping_servers(machine_names)
    Helpers.log("Invalid or missing machine name", 1) if machine_names.nil?
 
    machine_names.each do |key, value|
      if Ping.ping(value)
        puts key + ": ssh active"
      else
        puts key + ": non-responsive" 
      end
    end
  end
end

