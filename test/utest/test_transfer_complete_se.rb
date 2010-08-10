require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions/transfer_completed_se.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"


class Test_Helpers < Test::Unit::TestCase
  def setup
    @complete = Transfer_completed_se.new
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_completed_se
    Transfer_completed_se.publicize_methods do
      assert_raise SystemExit do
        @complete.completed_se(nil,nil)
      end

      assert_raise SystemExit do
        @complete.completed_se(Hash["sold0044", "128.249.153.237"],nil)
      end

      assert_nothing_raised do
	@complete.completed_se(Hash["sold0044", "128.249.153.237"], ["0044_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1"])
      end
    end
  end
# Public Methods ##############################################################
end
