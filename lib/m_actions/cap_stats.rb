#!/usr/bin/env ruby
#
# Author: David Chen

require 'fileutils'

class Cap_Stats
  def initialize(action)
    @app = action
  end

  def run(params)
    actions(@app, params[:outname], params[:bams].split, params[:outdir], 
            params[:project], params[:sub_dir], params[:c_design])
  end

  private

  def actions(action, name, bam_list, basedir, proj, subdir, cap_design)
    dir_path = basedir + "/" + proj + "/" + subdir

    # checking if the capture design is valid    
    if cap_design.nil? 
      Helpers::log("capture design not valid, exiting", 1)
    elsif !File.exists?(cap_design)
      Helpers::log("capture design path not valid, exiting", 1)
    end
  
    if bam_list.size > 1
      Helpers::log("more then one bam is specified for calling dups", 1)
    elsif action == "cap_dup"
      return [ cap_dup(dir_path, name, bam_list[0], cap_design), 
               $config["cap_stats"]["cap_mem"] ]
    elsif action == "cap_nodup"
      return [ cap_nodup(dir_path, name, bam_list[0], cap_design),
               $config["cap_stats"]["cap_mem"] ]
    end
  end

  def cap_stats_template(path, name, bam, cap_design, cap_dir)
    FileUtils.rm_rf("#{path}/#{cap_dir}")
    FileUtils.mkpath("#{path}/#{cap_dir}")
    cmd = "#{$config["java"]} -Xmx#{$config["cap_stats"]["cap_mem"]}M " +
          "-cp #{$config["cap_stats"]["class_path"]}" +
          " #{$config["cap_stats"]["cap_script"]} -o #{cap_dir}/#{name} " +
          "-t #{cap_design} -i #{bam} -w"
  end

  def cap_nodup(path, name, bam, cap_design)
    cap_stats_template(path, name, bam, cap_design, "cap_stats_nodup") + " -d"
  end

  def cap_dup(path, name, bam, cap_design)
    cap_stats_template(path, name, bam, cap_design, "cap_stats_dup")
  end
end
