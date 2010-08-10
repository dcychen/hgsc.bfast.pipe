#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#
require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__))
require 'use_private_method'
require 'fakedata'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/se_inst.rb"

class TestSeInst < Test::Unit::TestCase
  def setup
    @raw = Fakedata.new()
    @raw.ssh_fakerawdata
    @se = Se_inst.new("128.249.153.207")
  end

  def teardown
    @raw.rm_ssh_fakerawdata
  end

#/data/results/solid0044/0044_20100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/results.F1B1/libraries/defaultLibrary/primary.20100601143519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta
  def test_run_name_from_path
    assert_equal("0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4", 
                @se.run_name_from_path("/data/results/solid0044/0044_2" + 
                "0100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/result" +
                "s.F1B1/libraries/defaultLibrary/primary.20100601143519571" +
                "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100331" +
                "1175_4_F3.csfasta"))
    assert_equal("0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4" +
                "_BC1",
                @se.run_name_from_path("/data/results/solid0044/0044_2" +
                "0100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/result" +
                "s.F1B1/libraries/BC1/primary.20100601143519571" +
                "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100331" +
                "1175_4_F3_BC1.csfasta"))
    assert_equal("0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4" +
                "_BC3",
                @se.run_name_from_path("/data/results/solid0044/0044_2" +
                "0100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/result" +
                "s.F1B1/libraries/BC3/primary.20100601143519571" +
                "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100331" +
                "1175_4_R3_BC3.csfasta"))
    assert_equal("0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4" +
                "_BC5",
                @se.run_name_from_path("/data/results/solid0044/0044_2" +
                "0100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/result" +
                "s.F1B1/libraries/BC5/primary.20100601143519571" +
                "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100331" +
                "1175_4_F5-P2_BC5.csfasta"))

    assert_equal("0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4" +
                "_BC5",
                @se.run_name_from_path("/data/results/solid0044/0044_2" +
                "0100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/result" +
                "s.F1B1/libraries/BC5/primary.20100601143519571" +
                "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100331" +
                "1175_4_F5-P2_QV_BC5.qual"))
  end

  def test_latest_file
    Se_inst.publicize_methods do
      assert_equal(["results.F1B1/libraries/defaultLibrary/primary.2010060114" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_F3.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100601144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual"],
                   @se.get_latest_file(["results.F1B1/libraries/defaultLibra" +
                   "ry/primary.20100601143519571/reads/0044_20100525_1_SP_AN" +
                   "G_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta","results" +
                   ".F1B1/libraries/defaultLibrary/primary.20100601144519571" +
                   "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_010033" +
                   "11175_4_F3.csfasta", "results.F1B1/libraries/defaultLibr" +
                   "ary/primary.20100601143519271/reads/0044_20100525_1_SP_A" +
                   "NG_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta", "resul" +
                   "ts.F1B1/libraries/defaultLibrary/primary.201006011435195" +
                   "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                   "3311175_4_F3_QV.qual","results.F1B1/libraries/defaultLib" +
                   "rary/primary.20100601144519571/reads/0044_20100525_1_SP_" +
                   "ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual","resul" +
                    "ts.F1B1/libraries/defaultLibrary/primary.201006011435192" +
                   "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" + 
                   "3311175_4_F3_QV.qual"]))

      assert_equal(["results.F1B1/libraries/defaultLibrary/primary.2010060114" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_F3.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100601144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual", 
                   "results.F1B1/libraries/defaultLibrary/primary.2010060214" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_R3.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100602144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_R3_QV.qual"],
                   @se.get_latest_file(["results.F1B1/libraries/defaultLibra" +
                   "ry/primary.20100601143519571/reads/0044_20100525_1_SP_AN" +
                   "G_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta","results" +
                   ".F1B1/libraries/defaultLibrary/primary.20100601144519571" +
                   "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_010033" +
                   "11175_4_F3.csfasta", "results.F1B1/libraries/defaultLibr" +
                   "ary/primary.20100601143519271/reads/0044_20100525_1_SP_A" +
                   "NG_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta", "resul" +
                   "ts.F1B1/libraries/defaultLibrary/primary.201006011435195" +
                   "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                    "3311175_4_F3_QV.qual","results.F1B1/libraries/defaultLib" +
                   "rary/primary.20100601144519571/reads/0044_20100525_1_SP_" +
                   "ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual","resul" +
                   "ts.F1B1/libraries/defaultLibrary/primary.201006011435192" +
                   "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                   "3311175_4_F3_QV.qual",
                   "results.F1B1/libraries/defaultLibrary/primary.2010060114" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_R3.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100601144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_R3_QV.qual",
                   "results.F1B1/libraries/defaultLibrary/primary.2010060214" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_R3.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100602144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_R3_QV.qual"]))
  
      assert_equal(["results.F1B1/libraries/defaultLibrary/primary.2010060114" +
                    "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_F3.csfasta","results.F1B1/libraries/defau" +
                    "ltLibrary/primary.20100601144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual",
                   "results.F1B1/libraries/defaultLibrary/primary.2010060214" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_F5-P2.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100602144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F5-P2_QV.qual"],
                   @se.get_latest_file(["results.F1B1/libraries/defaultLibra" +
                   "ry/primary.20100601143519571/reads/0044_20100525_1_SP_AN" +
                   "G_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta","results" +
                   ".F1B1/libraries/defaultLibrary/primary.20100601144519571" +
                   "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_010033" +
                   "11175_4_F3.csfasta", "results.F1B1/libraries/defaultLibr" +
                   "ary/primary.20100601143519271/reads/0044_20100525_1_SP_A" +
                   "NG_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta", "resul" +
                   "ts.F1B1/libraries/defaultLibrary/primary.201006011435195" +
                   "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                   "3311175_4_F3_QV.qual","results.F1B1/libraries/defaultLib" +
                   "rary/primary.20100601144519571/reads/0044_20100525_1_SP_" +
                   "ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual","resul" +
                   "ts.F1B1/libraries/defaultLibrary/primary.201006011435192" +
                   "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                   "3311175_4_F3_QV.qual",
                   "results.F1B1/libraries/defaultLibrary/primary.2010060114" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_F5-P2.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100601144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F5-P2_QV.qual",
                   "results.F1B1/libraries/defaultLibrary/primary.2010060214" +
                   "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                   "_01003311175_4_F5-P2.csfasta","results.F1B1/libraries/defau" +
                   "ltLibrary/primary.20100602144519571/reads/0044_20100525_" +
                   "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F5-P2_QV.qual"]))
    end
  end

  def test_get_rname_path
    Se_inst.publicize_methods do
      assert_equal("/data/results/solid0533/0533_20100666_2_SL",
                   @se.get_rname_path("0533_20100666_2_SL_AWG_TOVA_61_1916_11" +
                   "A_N_2sA_01009999999_1"))
      assert_equal("/data/results/solid0533/0533_20100666_2_SL",
                    @se.get_rname_path("0533_20100666_2_SL"))
    end
  end
  
  def test_se_type
    Se_inst.publicize_methods do
      assert_equal("PE", 
                 @se.se_type?(["results.F1B1/libraries/defaultLibra" +
                 "ry/primary.20100601143519571/reads/0044_20100525_1_SP_AN" +
                 "G_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta","results" +
                 ".F1B1/libraries/defaultLibrary/primary.20100601144519571" +
                 "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_010033" +
                 "11175_4_F3.csfasta", "results.F1B1/libraries/defaultLibr" +
                 "ary/primary.20100601143519271/reads/0044_20100525_1_SP_A" +
                 "NG_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta", "resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435195" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual","results.F1B1/libraries/defaultLib" +
                 "rary/primary.20100601144519571/reads/0044_20100525_1_SP_" +
                 "ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual","resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435192" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual",
                 "results.F1B1/libraries/defaultLibrary/primary.2010060114" +
                 "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                 "_01003311175_4_F5-P2.csfasta","results.F1B1/libraries/defau" +
                 "ltLibrary/primary.20100601144519571/reads/0044_20100525_" +
                 "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F5-P2_QV.qual",
                 "results.F1B1/libraries/defaultLibrary/primary.2010060214" +
                 "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                 "_01003311175_4_F5-P2.csfasta","results.F1B1/libraries/defau" +
                 "ltLibrary/primary.20100602144519571/reads/0044_20100525_" +
                 "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F5-P2_QV.qual"]))

      assert_equal("MP",
                 @se.se_type?(["results.F1B1/libraries/defaultLibra" +
                 "ry/primary.20100601143519571/reads/0044_20100525_1_SP_AN" +
                 "G_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta","results" +
                 ".F1B1/libraries/defaultLibrary/primary.20100601144519571" +
                 "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_010033" +
                 "11175_4_F3.csfasta", "results.F1B1/libraries/defaultLibr" +
                 "ary/primary.20100601143519271/reads/0044_20100525_1_SP_A" +
                 "NG_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta", "resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435195" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual","results.F1B1/libraries/defaultLib" +
                 "rary/primary.20100601144519571/reads/0044_20100525_1_SP_" +
                 "ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual","resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435192" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual",
                 "results.F1B1/libraries/defaultLibrary/primary.2010060214" +
                 "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                 "_01003311175_4_R3.csfasta","results.F1B1/libraries/defau" +
                 "ltLibrary/primary.20100602144519571/reads/0044_20100525_" +
                 "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_R3_QV.qual"]))
      assert_equal("BC",
                 @se.se_type?(["results.F1B1/libraries/defaultLibra" +
                 "ry/primary.20100601143519571/reads/0044_20100525_1_SP_AN" +
                 "G_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta","results" +
                 ".F1B1/libraries/defaultLibrary/primary.20100601144519571" +
                 "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_010033" +
                 "11175_4_F3.csfasta", "results.F1B1/libraries/defaultLibr" +
                 "ary/primary.20100601143519271/reads/0044_20100525_1_SP_A" +
                 "NG_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta", "resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435195" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual","results.F1B1/libraries/defaultLib" +
                 "rary/primary.20100601144519571/reads/0044_20100525_1_SP_" +
                 "ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual","resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435192" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual",
                 "results.F1B1/libraries/defaultLibrary/primary.2010060214" +
                 "4519571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA" +
                 "_01003311175_4_F3_BC1.csfasta","results.F1B1/libraries/defau" +
                 "ltLibrary/primary.20100602144519571/reads/0044_20100525_" +
                 "1_SP_ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV_BC1.qual"]))

      assert_equal("FR",
                 @se.se_type?(["results.F1B1/libraries/defaultLibra" +
                 "ry/primary.20100601143519571/reads/0044_20100525_1_SP_AN" +
                 "G_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta","results" +
                 ".F1B1/libraries/defaultLibrary/primary.20100601144519571" +
                 "/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_010033" +
                 "11175_4_F3.csfasta", "results.F1B1/libraries/defaultLibr" +
                 "ary/primary.20100601143519271/reads/0044_20100525_1_SP_A" +
                 "04_TOVA_36_1580_01_2sA_01003311175_4_F3.csfasta", "resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435195" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual","results.F1B1/libraries/defaultLib" +
                 "rary/primary.20100601144519571/reads/0044_20100525_1_SP_" +
                 "ANG_TOVA_36_1580_01_2sA_01003311175_4_F3_QV.qual","resul" +
                 "ts.F1B1/libraries/defaultLibrary/primary.201006011435192" +
                 "71/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_0100" +
                 "3311175_4_F3_QV.qual"]))
     end
  end

  def test_path_parse
    assert_equal("solid0044", @se.path_parse("/data/results/solid004" +
                 "4/0044_20100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/" +
                 "results.F1B1/libraries/defaultLibrary/primary.2010060114351" +
                 "9571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003" +
                 "311175_4_F3.csfasta").mach)

    assert_equal("0044_20100525_1_SP", @se.path_parse("/data/results/solid004" +
                 "4/0044_20100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/" +
                 "results.F1B1/libraries/defaultLibrary/primary.2010060114351" +
                 "9571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003" +
                 "311175_4_F3.csfasta").rname)

    assert_equal("ANG_TOVA_36_1580_01_2sA_01003311175_4", @se.path_parse("/da" +
                 "ta/results/solid0044/0044_20100525_1_SP/ANG_TOVA_36_1580_01" +
                 "_2sA_01003311175_4/results.F1B1/libraries/defaultLibrary/pr" +
                 "imary.20100601143519571/reads/0044_20100525_1_SP_ANG_TOVA_3" +
                 "6_1580_01_2sA_01003311175_4_F3.csfasta").sample)

    assert_equal("defaultLibrary", @se.path_parse("/data/results/solid004" +
                 "4/0044_20100525_1_SP/ANG_TOVA_36_1580_01_2sA_01003311175_4/" +
                 "results.F1B1/libraries/defaultLibrary/primary.2010060114351" +                                                  "9571/reads/0044_20100525_1_SP_ANG_TOVA_36_1580_01_2sA_01003" +
                 "311175_4_F3.csfasta").bc)
  end

  def test_ssh_hostname
    assert_equal("solid0533", @se.ssh_hostname)
  end
  
  def test_se_on_machine
    assert_equal(TRUE, @se.se_on_machine("0533_20100666_2_SL_AWG_TOVA_61_1916" +
                 "_11A_N_2sA_01009999999_1"))
  end
  
  def test_place_flag_completed
    Se_inst.publicize_methods do
      assert_equal(FALSE, @se.completed_se?("0533_20100666_2_SL"))
      @se.place_done_flag("0533_20100666_2_SL")
      assert_equal(TRUE, @se.completed_se?("0533_20100666_2_SL"))
      assert_equal(TRUE, @se.completed_run.include?("0533_20100666_2_SL"))
    end
  end

  def test_matching_keys
    assert_equal(["0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2sA_01009999999_1"],
                 @se.matching_keys("0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N" +
                 "_2sA_01009999999_1"))
  end
end

