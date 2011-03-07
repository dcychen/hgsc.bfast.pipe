#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# This is the interface between the transfer driver class and the
# individual actions. It loads all of the action classes, then
# calls the run method for the specified one.
#
# Author: David Chen

class Mu_actions
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
      when "merge"
        Helpers::log "Instanciating Action: #{@a_string}"
        Run_Picard.new("merge")
      when "dups"
        Helpers::log "Instanciating Action: #{@a_string}"
        Run_Picard.new("dups")
      when "cap_dup"
        Helpers::log "Instanciating Action: #{@a_string}"
        Cap_Stats.new("cap_dup")
      when "cap_nodup"
        Helpers::log "Instanciating Action: #{@a_string}"
        Cap_Stats.new("cap_nodup")
      when "snps"
        Helpers::log "Instanciating Action: #{@a_string}"
        Call_SNPs.new("snps")
      when "rg"
        Helpers::log "Instanciating Action: #{@a_string}"
        RG_Fix.new("rg")
      else
        Helpers::log("ERROR: cannot find action: #{@a_string}", 1)
        exit 1
    end
  end

  # Load all the actions available
  #
  def load_actions
    lib_dir = File.dirname(__FILE__)

    a_lib_dir = lib_dir + "/m_actions"
    a_files   = Dir[File.join(a_lib_dir, "*.rb")]

    Dir[File.join(a_lib_dir, "*.rb")].each do |file|
      f = a_lib_dir + "/" + File.basename(file.gsub(/\.rb$/,''))
      Helpers::log "Loading action: #{f}"
      require f
    end
  end
end
