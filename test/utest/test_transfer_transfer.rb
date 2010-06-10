require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions/transfer_transfer.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"


class Test_Helpers < Test::Unit::TestCase
  def setup
    @transfer = Transfer_transfer.new
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_transfer
    Transfer_transfer.publicize_methods do
      assert_raise SystemExit do
        @transfer.transfer(nil, nil, nil, nil)
      end

      assert_raise SystemExit do
        @transfer.transfer(Hash["sold0044", "128.249.153.237"],nil,nil,nil)
      end

      assert_nothing_raised do
        @transfer.transfer(Hash["sold0044", "128.249.153.237"],nil,4,nil)
      end
    end
  end
# Public Methods ##############################################################
end
