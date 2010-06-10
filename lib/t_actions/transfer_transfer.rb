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

class Transfer_transfer

  def initialize
    @home  = "#{ENV['HOME']}/.hgsc_solid"
  end

  def run(params)
    transfer(params[:m_name], params[:e_addr], params[:snfs], params[:r_name])
  end
  
  private
  
  def transfer(machine_names, email, snfs, run_names)
    Helpers::log("Invalid or missing machine name", 1) if machine_names.nil?
    Helpers::log("Invalid or missing snfs number", 1) if snfs.nil?
    if (run_names.nil?)
      machine_names.each do |key, value|
        tempThread = fork{machineParallel(key, value, email, snfs)}
      end
    else
      run_names.each do |name|
        tempThread = fork{nameParallel(machine_names, name, email, snfs)}
      end
    end
    Process.waitall


  end

  def machineParallel(key, value, email, snfs)
    dir = @home + "/#{key}"
    file = dir + "/#{key}_active_transfer.txt"
    if !File.directory?(dir) || !File.exist?(file)
      FileUtils.mkdir_p(dir)
      File.new(file, "w")
    end
    File.open(file, "a") {|f| f.puts(Process.pid)}

    em = 0
    em = 1 if !email.nil? && !email.empty?

    temp_tr = Solid_transfer.new(value, email)
    temp_tr.transfer(snfs, "all", 0)
    temp_tr.completed_se(snfs, "all", em)

    active = File.readlines(file)
    active.delete("#{Process.pid}\n")
    
    if active.empty?
      File.delete(file)
    else
      File.open(file, 'w') do |f|
        f.puts active
      end
    end
  end

  def nameParallel(machine_names, name, email, snfs)
    machine = name.slice(0,4)
    dir = @home + "/solid#{machine}"
    file = dir + "/solid#{machine}_active_transfer.txt"

    em = 0
    em = 1 if !email.nil? && !email.empty?

    if !File.directory?(dir) || !File.exist?(file)
      FileUtils.mkdir_p(dir)
      File.new(file, "w")
    end
    File.open(file, "a") {|f| f.puts(Process.pid)}

    temp_tr = Solid_transfer.new(machine_names["solid" + machine], email)
    temp_tr.transfer(snfs, name, em)
    temp_tr.completed_se(snfs, name, em)

    active = File.readlines(file)
    active.delete("#{Process.pid}\n")
   
    if active.empty?
      File.delete(file)
    else
      File.open(file, 'w') do |f|
        f.puts active
      end 
    end 
  end
end
