#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#
require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__))
require 'fakedata'
require 'use_private_method'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/solid_transfer.rb"

class TestSolidTransfer < Test::Unit::TestCase
  def setup
    @raw = Fakedata.new()
    @raw.ssh_fakerawdata
    @st = Solid_transfer.new("128.249.153.207", nil)
  end

  def teardown
    @raw.rm_ssh_fakerawdata
  end

  def test_md5sum_file
    Solid_transfer.publicize_methods do
       @raw.fakerawdata("F3")
      assert_equal("230d5476f165646df22d47932732344e", @st.md5sum_file(
                   "0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2sA_01009999999_1" +
                   "_F3.csfasta").split[0])
      assert_equal("f891b4f0d7f345be4850e53352147dae", @st.md5sum_file(
                   "0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2sA_01009999999_1" +
                   "_F3_QV.qual").split[0])
      @raw.rm_fakerawdata
    end
  end

  def test_ssh_md5sum_file
    Solid_transfer.publicize_methods do
      assert_equal("f891b4f0d7f345be4850e53352147dae", @st.ssh_md5sum_file(
                   "/data/results/solid0533/0533_20100666_2_SL/AWG_TOVA_61_1916" +
                   "_11A_N_2sA_01009999999_1/results.F1B1/libraries/defaultLibr" +
                   "ary/primary.20100612145459025/reads/0533_20100666_2_SL_AWG_" +
                   "TOVA_61_1916_11A_N_2sA_01009999999_1_F3_QV.qual").split[0])
    end
  end

  def test_get_bp_length
    @raw.fakerawdata("F3")
    Solid_transfer.publicize_methods do
      assert_equal(50, @st.get_bp_length("0533_20100666_2_SL_AWG_TOVA_61_1916_1" +
                   "1A_N_2sA_01009999999_1_F3.csfasta"))
    end
    @raw.rm_fakerawdata
  end

  def test_check_fasta
    @raw.fakerawdata("F3")
    Solid_transfer.publicize_methods do
      assert_equal("", @st.check_csfasta("0533_20100666_2_SL_AWG_TOVA_61_1916_1" +
                   "1A_N_2sA_01009999999_1_F3.csfasta"))
    end
    @raw.rm_fakerawdata
  end

  def test_locks
    Solid_transfer.publicize_methods do
      assert_equal(FALSE, @st.check_lock("0708_20100506_2_SP_AZZ_MID0040_ZZ_sA_01003" +
             "311058_1_F3_BC99"))
      @st.create_lock("0708_20100506_2_SP_AZZ_MID0040_ZZ_sA_01003311058_1_F3_BC99")
      assert(TRUE, @st.check_lock("0708_20100506_2_SP_AZZ_MID0040_ZZ_sA_01003" +
             "311058_1_F3_BC99"))
      @st.remove_lock("0708_20100506_2_SP_AZZ_MID0040_ZZ_sA_01003311058_1_F3_BC99")
      assert_equal(FALSE, @st.check_lock("0708_20100506_2_SP_AZZ_MID0040_ZZ_sA_01003" +
             "311058_1_F3_BC99"))
    end
  end

  def test_md5_from_file
    Solid_transfer.publicize_methods do
      @st.add_line_to_file("lallatest.txt", "230d5476f165646df22d47932732344e " +
                           "0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2sA_01009" +
                           "999999_1_F3.csfasta")
      @st.add_line_to_file("lallatest.txt", "f891b4f0d7f345be4850e53352147dae " +
                             "0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2sA_01009" +
                           "999999_1_F3_QV.qual")
      assert_equal("f891b4f0d7f345be4850e53352147dae",
                   @st.grab_md5_from_file("lallatest.txt", "0533_20100666_2_SL_" +
                   "AWG_TOVA_61_1916_11A_N_2sA_01009999999_1_F3_QV.qual").split[0])
      assert_equal("230d5476f165646df22d47932732344e",
                   @st.grab_md5_from_file("lallatest.txt", "0533_20100666_2_SL_" +
                   "AWG_TOVA_61_1916_11A_N_2sA_01009999999_1_F3.csfasta").split[0])
      @st.rm_md5_from_file("lallatest.txt", "0533_20100666_2_SL_" +
                   "AWG_TOVA_61_1916_11A_N_2sA_01009999999_1_F3.csfasta")
      assert_equal("", @st.grab_md5_from_file("lallatest.txt", "0533_20100666_2" +
                   "_SL_AWG_TOVA_61_1916_11A_N_2sA_01009999999_1_F3.csfasta"))
    end
    File.delete("lallatest.txt")
  end

  def test_check_new
    Solid_transfer.publicize_methods do
      @st.add_line_to_file("lallatest.txt", "testing_OVA_61")
      assert_equal(TRUE, @st.check_new?("0533_20100666_2_SL_AWG_TOVA_61" +
                   "_1916_11A_N_2sA_01009999999_2", "lallatest.txt",0))

      @st.add_line_to_file("lallatest.txt", "0533_20100666_2_SL_AWG_TOVA_61" +
                           "_1916_11A_N_2sA_01009999999_1")
      assert_equal(FALSE, @st.check_new?("0533_20100666_2_SL_AWG_TOVA_61" +
                   "_1916_11A_N_2sA_01009999999_1", "lallatest.txt",0))
    end
    File.delete("lallatest.txt")
  end

  def test_run_name_path
    Solid_transfer.publicize_methods do
      assert_equal("/stornext/snfs5/next-gen/solid/results/solid0533/2010/06/05" +
                   "33_20100666_2_SL",
                   @st.run_name_path(5, "0533_20100666_2_SL_AWG_TOVA_61_1916_11" +
                   "A_N_2sA_01009999999_1"))
      assert_equal("/stornext/snfs5/next-gen/solid/results/solid0533/2010/06/05" +
                   "33_20100666_2_SL",
                   @st.run_name_path(5, "0533_20100666_2_SL_AWG_TOVA_61_1916_11" +
                   "A_N_2sA_01009999999_1_BC23"))
    end
  end

  def test_dest_path
    Solid_transfer.publicize_methods do
      assert_equal("/stornext/snfs5/next-gen/solid/results/solid0533/2010/06/05" +
                   "33_20100666_2_SL/AWG_TOVA_61_1916_11A_N_2sA_01009999999_1",
                   @st.dest_path(5, "/data/results/solid0533/0533_20100666_2_SL" +
                   "/AWG_TOVA_61_1916_11A_N_2sA_01009999999_1/results.F1B1/libr" +
                   "aries/defaultLibrary/primary.20100612145459025/reads/0533_2" +
                   "0100666_2_SL_AWG_TOVA_61_1916_11A_N_2sA_01009999999_1_F3_QV" +
                   ".qual"))
      assert_equal("/stornext/snfs5/next-gen/solid/results/solid0533/2010/06/05" +
                   "33_20100666_2_SL/AWG_TOVA_61_1916_11A_N_2sA_01009999999_1/B" +
                   "C99", @st.dest_path(5, "/data/results/solid0533/0533_201006" +
                   "66_2_SL/AWG_TOVA_61_1916_11A_N_2sA_01009999999_1/results.F1" +
                    "B1/libraries/BC99/primary.20100612145459025/reads/0533_2" +
                   "0100666_2_SL_AWG_TOVA_61_1916_11A_N_2sA_01009999999_1_F3_BC" +
                   "99.csfasta"))
    end
  end
  
  def test_add_line_to_file
    Solid_transfer.publicize_methods do
      @st.add_line_to_file("abcdlallatest.txt", "testing lalala")
      assert_equal("testing lalala\n", 
                   File.open("abcdlallatest.txt","r").readline)
    end
    File.delete("abcdlallatest.txt")  
  end

  def test_check_transferred
    Solid_transfer.publicize_methods do
      @st.add_line_to_file("abcdlallatest.txt", "testing_OVA_61")
      assert_equal(FALSE, @st.check_transferred?("0533_20100666_2_SL_AWG_TOVA_61" +
                   "_1916_11A_N_2sA_01009999999_2", "abcdlallatest.txt"))

      @st.add_line_to_file("abcdlallatest.txt", "0533_20100666_2_SL_AWG_TOVA_61" +
                           "_1916_11A_N_2sA_01009999999_1")
      assert_equal(TRUE, @st.check_transferred?("0533_20100666_2_SL_AWG_TOVA_61" +
                   "_1916_11A_N_2sA_01009999999_1", "abcdlallatest.txt"))
    end
    File.delete("abcdlallatest.txt")
  end
end
