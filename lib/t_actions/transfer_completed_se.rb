#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# This class parses the machine and run names then calls the
# appropriate methods to place the slide_done flag.
#

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/se_inst.rb"

class Transfer_completed_se
  def initialize
  end

  def run(params)
    completed_se(params[:m_name], params[:r_name])
  end
  
  private
  
  def completed_se(machine_names, run_names)
    Helpers::log("Invalid or missing machine name", 1) if machine_names.nil?
    Helpers::log("Invalid or missing run name", 1) if run_names.nil?
    
    run_names.each do |name|
       machine = name.slice(0,4)
       ip = machine_names["solid" + machine]
       Helpers.log("Invalid machine name", 1) if ip.nil?
       temp_tr = Se_inst.new(ip)
       temp_tr.place_done_flag(name)
    end
  end
end

