require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions/transfer_stop.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"


class Test_Helpers < Test::Unit::TestCase
  def setup
    @stop = Transfer_stop.new
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_ping_servers
    Transfer_stop.publicize_methods do
      assert_raise SystemExit do
        @stop.stop(nil)
      end

      assert_nothing_raised do
        @stop.stop(Hash["sold0044", "128.249.153.237"])
      end
    end
  end
# Public Methods ##############################################################
end
