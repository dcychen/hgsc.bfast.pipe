require 'test/unit'
require 'fileutils'
require 'date'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/t_actions/transfer_disk_usage.rb"
require main_dir + "/lib/helpers.rb"
require main_dir + "/test/utest/use_private_method.rb"


class Test_Helpers < Test::Unit::TestCase
  def setup
    @disk = Transfer_disk_usage.new
  end
  
  def teardown
  end

# Private Methods #############################################################

  def test_disk_usage
    Transfer_disk_usage.publicize_methods do
      assert_raise SystemExit do
        @disk.disk_usage(nil, nil)
      end

      assert_nothing_raised do
        @disk.disk_usage(Hash["sold0044", "128.249.153.237"], nil)
      end
    end
  end
# Public Methods ##############################################################
end
