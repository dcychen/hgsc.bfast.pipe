require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions/transfer_se_ready.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"


class Test_Helpers < Test::Unit::TestCase
  def setup
    @ready = Transfer_se_ready.new
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_ready
    Transfer_se_ready.publicize_methods do
      assert_raise SystemExit do
        @ready.ready(nil,nil)
      end
   
      assert_raise SystemExit do
        @ready.ready(Hash["sold0044", "128.249.153.237"], nil)
      end

      assert_nothing_raised do
        @ready.ready(Hash["sold0044", "128.249.153.237"], ["0044_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1"])
      end
    end
  end
# Public Methods ##############################################################
end
