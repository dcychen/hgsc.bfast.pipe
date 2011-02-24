#!/usr/bin/env ruby
#
# Author: David Chen

require 'fileutils'

class Run_Picard
  def initialize(action)
    @app = action
  end

  def run(params)
    actions(@app, params[:outname], params[:bams].split, params[:outdir], 
            params[:project], params[:sub_dir])
  end

  private

  def actions(action, name, bam_list, basedir, proj, subdir)
    dir_path = basedir + "/" + proj + "/" + subdir

    if action == "merge"
      if File.exists?("#{dir_path}/#{name}.merged.bam")
        Helpers::log("#{dir_path}/#{name}.merged.bam exists already.. exiting", 1)
      else
        return [ merge_bams(name, bam_list), $config["picard"]["merge_mem"] ]
      end
    elsif action == "dups"
      if File.exists?("#{dir_path}/#{name}.dups.bam")
        Helpers::log("#{dir_path}/#{name}.dups.bam exists already.. exiting", 1)
      elsif bam_list.size > 1
        Helpers::log("more then one bam is specified for calling dups", 1)
      else
        return [ dup_bam(name, bam_list) + " && " + remove_merge_bam(name), 
                 $config["picard"]["dups_mem"] ]
      end
    end
  end

  def merge_bams(name, bam_list)
    cmd = "#{$config["java"]} -Xmx#{$config["picard"]["merge_mem"]}M " + 
          "-jar #{$config["picard"]["merge_jar"]} "
    bam_list.each { |b| cmd = cmd + "INPUT=#{b} "}
    cmd = cmd + "ASSUME_SORTED=TRUE TMP_DIR=#{$config["tmp_space"]} " +
          "VERBOSITY=INFO VALIDATION_STRINGENCY=STRICT SORT_ORDER=coordinate " +
          "OUTPUT=#{name}.merged.bam"
  end

  def dup_bam(name, bam_list)
    input = bam_list[0]
    cmd = "#{$config["java"]} -Xmx#{$config["picard"]["dups_mem"]}M " + 
          "-jar #{$config["picard"]["dups_jar"]} " +
          "TMP_DIR=#{$config["tmp_space"]} INPUT=#{input} " +
          "METRICS_FILE=./metric_file.picard VERBOSITY=ERROR " +
          "VALIDATION_STRINGENCY=STRICT OUTPUT=#{name}.dups.bam"
  end
  
  def remove_merge_bam(name)
    cmd = "rm #{name}.merged.bam metric_file.picard"
  end
end
