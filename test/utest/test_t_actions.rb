#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#

# Test negative cases

require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"

class Test_Helpers < Test::Unit::TestCase
  def setup
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_load_actions
    action = Transfer_actions.new("ping")
    Transfer_actions.publicize_methods do
      action.load_actions
      assert_nothing_raised do
        Transfer_ping.new
        Transfer_list_se.new
        Transfer_disk_usage.new
        Transfer_transfer.new
        Transfer_completed_se.new
        Transfer_stop.new
      end
    end
  end

  def test_create_action
    Transfer_actions.publicize_methods do
      ping = Transfer_actions.new("ping")
      assert_equal("Transfer_ping", ping.create_action.class.to_s)

      list_se = Transfer_actions.new("list_se")
      assert_equal("Transfer_list_se", list_se.create_action.class.to_s)

      disk_usage = Transfer_actions.new("disk_usage")
      assert_equal("Transfer_disk_usage", disk_usage.create_action.class.to_s)

      se_ready = Transfer_actions.new("se_ready")
      assert_equal("Transfer_se_ready", se_ready.create_action.class.to_s)

      transfer = Transfer_actions.new("transfer")
      assert_equal("Transfer_transfer", transfer.create_action.class.to_s)

      completed_se = Transfer_actions.new("completed_se")
      assert_equal("Transfer_completed_se", completed_se.create_action.class.to_s)

      stop = Transfer_actions.new("stop")
      assert_equal("Transfer_stop", stop.create_action.class.to_s)
    end
  end

# Public Methods ##############################################################

  def test_get_action
      ping = Transfer_actions.new("ping")
      assert_equal("Transfer_ping", ping.get_action.class.to_s)

      list_se = Transfer_actions.new("list_se")
      assert_equal("Transfer_list_se", list_se.get_action.class.to_s)

      disk_usage = Transfer_actions.new("disk_usage")
      assert_equal("Transfer_disk_usage", disk_usage.get_action.class.to_s)

      se_ready = Transfer_actions.new("se_ready")
      assert_equal("Transfer_se_ready", se_ready.get_action.class.to_s)

      transfer = Transfer_actions.new("transfer")
      assert_equal("Transfer_transfer", transfer.get_action.class.to_s)

      completed_se = Transfer_actions.new("completed_se")
      assert_equal("Transfer_completed_se", completed_se.get_action.class.to_s)

      stop = Transfer_actions.new("stop")
      assert_equal("Transfer_stop", stop.get_action.class.to_s)
  end
end
