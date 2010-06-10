#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# Thhis class takes in a machine name, email, destination snfs,
# and run name. It then calls the transfer method using these
# parameters.
#

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/solid_transfer.rb"

class Transfer_se_ready
  def initialize
  end

  def run(params)
    ready(params[:m_name], params[:r_name])
  end
  
  private
  
  def ready(machine_names, run_names)
    Helpers::log("Invalid or missing machine name", 1) if machine_names.nil?
    Helpers::log("Invalid or missing run name", 1) if run_names.nil?
    run_names.each do |name|
          machine = name.slice(0,4)
          temp_tr = Solid_transfer.new(machine_names["solid" + machine], nil)
          temp_tr.check_ready_for_analysis?(name)
    end
  end
end
