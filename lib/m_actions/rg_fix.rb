#!/usr/bin/env ruby
#
# Author: David Chen

require 'fileutils'

class RG_Fix 
  def initialize(action)
    @app = action
  end

  def run(params)
    actions(@app, params[:outname], params[:bams].split, params[:outdir], 
            params[:project], params[:sub_dir], params[:sample], 
            params[:rg_id])
  end

  private

  def actions(action, name, bam_list, basedir, proj, subdir, samp, rg_id)
    dir_path = basedir + "/" + proj + "/" + subdir

    if !File.directory?(dir_path)
      Helpers::log("#{dir_path} does not exist, creating dir")
      FileUtils.makedirs(dir_path)
    end

    if bam_list.size > 1
      Helpers::log("more then one bam is specified for rg fix", 1)
    end
 
    rg_cmd = gen_rg(bam_list[0], rg_id, name, subdir, samp, "#{name}.rg.bam")
    cmd = "cd #{dir_path} && #{rg_cmd}"

    return [ cmd, $config["rg"]["rg_mem"] ]
  end

  def gen_rg(input, rg_id, name, lib, sample, outname)
    cmd = "#{$config["java"]} " +
          "-jar #{$main_dir}/java/AddRGToBam/AddRGToBam.jar " +
          "SampleID=#{sample} " +
          "Library=#{lib} " +
          "Platform=SOLiD " +
          "PlatformUnit=#{name} " +
          "RGTag=#{rg_id} " +
          "Input=#{input} " +
          "Output=#{outname} "
  end
end
