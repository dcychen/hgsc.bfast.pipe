#!/usr/bin/env ruby
#
# Author: David Chen

require 'fileutils'

class Call_SNPs 
  def initialize(action)
    @app = action
  end

  def run(params)
    actions(@app, params[:outname], params[:bams].split, params[:outdir], 
            params[:project], params[:sub_dir], params[:ref])
  end

  private

  def actions(action, name, bam_list, basedir, proj, subdir, ref)
    dir_path = basedir + "/" + proj + "/" + subdir + "/snps"

    if File.directory?(dir_path)
      Helpers::log("#{dir_path} exists, cleaning..")
      FileUtils.rm_rf(dir_path)
      FileUtils.makedirs(dir_path)
    else
      Helpers::log("#{dir_path} does not exist, creating dir")
      FileUtils.makedirs(dir_path)
    end

    if bam_list.size > 1
      Helpers::log("more then one bam is specified for calling snps", 1)
    end
    main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
    snp_script = "#{main_dir}/third.party/SNP_calling_annotation_hg19.pl"
    if ref == "hg18"
      snp_script = "#{main_dir}/third.party/SNP_calling_annotation.pl"
    end
    
    cmd = "cd #{dir_path} && #{snp_script} #{bam_list[0]} #{dir_path}"

    return [ cmd, $config["snp"]["filterbam_mem"] ]
  end
end
