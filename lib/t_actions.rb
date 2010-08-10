#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# This is the interface between the transfer driver class and the
# individual actions. It loads all of the action classes, then
# calls the run method for the specified one.
#

class Transfer_actions
  def initialize(action_string)
    @a_string = action_string
    load_actions
  end

  def get_action
    create_action
  end

  private

  # create the necessary action class
  #
  def create_action
    case @a_string
      when "ping"
        Helpers::log "Instanciating Action: #{@a_string}"
        Transfer_ping.new
      when "list_se"
        Helpers::log "Instanciating Action: #{@a_string}"
        Transfer_list_se.new
      when "disk_usage"
        Helpers::log "Instanciating Action: #{@a_string}"
        Transfer_disk_usage.new
      when "se_ready"
        Helpers::log "Instanciating Action: #{@a_string}"
        Transfer_se_ready.new
      when "transfer"
        Helpers::log "Instanciating Action: #{@a_string}"
        Transfer_transfer.new
      when "completed_se"
        Helpers::log "Instanciating Action: #{@a_string}"
        Transfer_completed_se.new
      when "stop"
        Helpers::log "Instanciating Action: #{@a_string}"
        Transfer_stop.new
      else
        Helpers::log("ERROR: cannot find action: #{@a_string}", 1)
        exit 1
    end
  end

  # Load all the actions available
  #
  def load_actions
    #bin_dir  = File.dirname($0)
    #main_dir = File.dirname(bin_dir)
    
    lib_dir = File.dirname(__FILE__)

    #lib_dir   = File.join(main_dir, "lib")
    a_lib_dir = lib_dir + "/t_actions"
    a_files   = Dir[File.join(a_lib_dir, "*.rb")]
    
    Dir[File.join(a_lib_dir, "*.rb")].each do |file|
      f = a_lib_dir + "/" + File.basename(file.gsub(/\.rb$/,''))
      Helpers::log "Loading action: #{f}"
      require f
    end
  end
end
