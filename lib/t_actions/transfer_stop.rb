#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# This class takes in a list of machines and stops all rsync transfers
# from that machine.
#
# Author: Phillip Coleman

$main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require $main_dir + "/lib/solid_transfer.rb"

class Transfer_stop
  def initialize
    load_machine_list
  end

  def run(params)
    stop(params[:m_name])
  end
  
  private
  
  def stop(machine_names)
    Helpers::log("Invalid or missing machine name", 1) if machine_names.nil?  

    machine_names.each do |key, value|
      puts "Stopping transfers on #{key}"
      dir = "#{ENV['HOME']}/.hgsc_solid/#{key}/#{key}_active_transfer.txt"
      if File.exist?(dir)
        File.open(dir, "r") do |infile|
          while (line = infile.gets)
            @pid = line
            @list.each do |key1, value1|
              if value1.member?(key)
            
                Net::SSH.start(key1, "p-solid") do |ssh|
                  ssh.exec! "kill #{@pid}"
                end
              end 
            end
          end
          File.delete("#{ENV['HOME']}/.hgsc_solid/#{key}/#{key}_active_transfer.txt")
          lock_files = Dir.glob("#{ENV['HOME']}/.hgsc_solid/#{key}/*.lock")
          lock_files.each do |l|
            File.delete(l)
          end
        end

        trans = Solid_transfer.new(value, nil)
        trans.stop_rsync

      else
        Helpers.log("No active transfers", 0)
      end
    end
  end

  def load_machine_list
    name = Socket.gethostname
    list_file = $main_dir + "/etc/split.machine_list.yaml"
    obj = ""
    File.open(list_file, "r") do |infile|
      while (line = infile.gets)
        obj << line
      end
    end
    @list = YAML::load(obj)
  end
end
