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
=begin
    cmd = filterBam(name, bam_list) + " && " + index(name)
    cmd = cmd + " && " + pileup(name, ref)
    cmd = cmd + " && " + filterPileUpUniversal(name)
    cmd = cmd + " && " + outputSnp_Indels(name)


#    filterBam(name, bam_list)
    #index(name)
#    puts pileup(name, ref)
#    puts filterPileUpUniversal(name)
#    puts outputSnp_Indels(name)

    # currently no annotation for hg19
    if ref == "hg18"
#     puts annotate_ard(name)
#     puts annotate_miRNA(name)
      cmd = cmd + " && " + annotate_ard(name)
      cmd = cmd + " && " + annotate_miRNA(name)
    end
    
    return [ cmd, $config["snp"]["filterbam_mem"] ]
  end

  def filterBam(name, bam_list)
    cmd = "#{$config["java"]} -cp #{$config["snp"]["class_path"]} " +
          "-Xmx#{$config["snp"]["filterbam_mem"]}M FilterBAMForSNPCalling " +
          "#{bam_list[0]} #{name}.sorted.dups.removed.bam"
  end

  def index(name)
    cmd = "#{$config["samtools"]} index #{name}.sorted.dups.removed.bam"
  end


  def pileup(name, ref)
    h_ref = $config["h19_ref"]
    if ref == "hg18"
      h_ref = $config["h18_ref"]
    end
    cmd = "#{$config["samtools"]} pileup -vcf #{h_ref} " +
          "#{name}.sorted.dups.removed.bam >& #{name}.sorted.dups.removed.raw.pileup"
  end

  def filterPileUpUniversal(name)
    cmd = "#{$config["java"]} -cp #{$config["snp"]["class_path"]} " +
      "-Xmx#{$config["snp"]["filterpile_mem"]}M " + 
      "#{name}.sorted.dups.removed.raw.pileup > #{name}.GV"
  end
  
  def outputSnp_Indels(name)
=begin
    snp = File.open("#{name}.SNPs", "w+")
    indel = File.open("#{name}.INDELs", "w+")

    File.open("#{name}.GV", "r").readline do |f|
      tmp = f.split("\t")
      if temp[2] != "*"
        snp.write(f)
      else
        indel.write(f)
      end
    end
    snp.close
    indel.close
=end
=begin

    cmd = "#{File.dirname(__FILE__)}/../../helpers/outputSnp_Indels.rb #{name}"
  end

  def annotate_ard(name)
    cmd = "#{$config["snp"]["annotate"]} -c 0,1,2,2,3 -d 130 -i #{name}.SNPs"
  end

  def annotate_miRNA(name)
    cmd = "#{$config["snp"]["mirna_annotate"]} -c 0,1,2,2,3 -i #{name}.SNPs"
  end
end

=end
