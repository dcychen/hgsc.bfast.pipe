#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# This class parses the machine names and the optional run names.
# It then calls the appropriate methods to list out the sequence
# event information. This consists of run name, type and the
# paths for the files.
#

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/se_inst.rb"

class Transfer_list_se
  def initialize
  end

  def run(params)
    list_se(params[:m_name], params[:r_name])
  end
  
  private
  
  def list_se(machine_names, run_names)
    Helpers::log("Invalid or missing machine name", 1) if machine_names.nil?  

    @finish = false
    machine_names.each do |key, value|
      if run_names == nil
        temp_se = Se_inst.new(value)
        temp_se.se_on_machine
      else
        run_names.each do |name|
          temp_se = Se_inst.new(value)
          if temp_se.se_on_machine(name)
            @finish = true
            break
          end
        end
	if @finish
          break
        end
      end
    end
  end
end

