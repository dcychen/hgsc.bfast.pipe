require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions/transfer_ping.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"


class Test_Helpers < Test::Unit::TestCase
  def setup
    @ping = Transfer_ping.new
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_ping_servers
    Transfer_ping.publicize_methods do
      assert_raise SystemExit do
        @ping.ping_servers(nil)
      end
    end
  end
# Public Methods ##############################################################
end
