require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions/transfer_list_se.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"


class Test_Helpers < Test::Unit::TestCase
  def setup
    @list = Transfer_list_se.new
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_list_se
    Transfer_list_se.publicize_methods do
      assert_raise SystemExit do
        @list.list_se(nil, nil)
      end

      assert_nothing_raised do
        @list.list_se(Hash["sold0044", "128.249.153.237"], [nil])
      end

      assert_nothing_raised do
        @list.list_se(Hash["sold0044", "128.249.153.237"], ["0000"])
      end
    end
  end

# Public Methods ##############################################################
end
