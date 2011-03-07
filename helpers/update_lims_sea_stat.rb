#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
# 
# Updates LIMS
# usage: ruby update_lims.rb  
#   It will use the current path that it is in.
#
# Author: David Chen 

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'ostruct'
require 'find'
require 'helpers'

# this is the list of valid keys to expect in the 
# stats files
KEYS_PER_TAG = %w{
  XX_total_reads_considered
  XX_total_reads_mapped
  XX_throughput
  XX_effective_throughput 
}.freeze

# csv header
HEADER = %w{
  name start end ref bfast picard mode gatk bam_path 
  F3_total_reads_considered F3_total_reads_mapped F3_throughput F3_effective_throughput
  R3_total_reads_considered R3_total_reads_mapped R3_throughput R3_effective_throughput
}

# csv delimiter
DELIMITER = ","

# Find requires a "/" in order to traverse a dir. Weird
class String
  def extra_slash
    self[-1] == "/" ? self : "#{self}/"
  end
end

# Find bams in s_dir
def find_bams(s_dir)
  bams = []
  Find.find(s_dir) do |f|
    bams << f if File.file?(f) and
                 (f =~ %r{sorted.dups.bam$} or
                  f =~ %r{sorted.dups.with.header.bam$} or
                  f =~ %r{merged.marked.bam$})
  end
  bams
end

# Find stats files
# marked.stats.txt # marked.stats.F3.txt # marked.stats.R3.txt
def find_stats_files(s_dir)
  stats_files = []
  Dir[s_dir + "/*stats*"].each do |f|
    stats_files << f if f =~ %r{marked.stats[.F3|.R3]*.txt$}x and 
                        File.file?(f) and File.size?(f)
  end

  # Either 1 stats file
  # Or 2 stats file (R3|F3)
  if (stats_files.size == 1 and
      stats_files[0].split("/")[-1] == "marked.stats.txt") or
     (stats_files.size == 2 and
      stats_files[0].split("/")[-1] == "marked.stats.R3.txt" and
      stats_files[1].split("/")[-1] == "marked.stats.F3.txt")
    stats_files
  else
    []
  end 
end

# Parse the stats and gather key values for lims
def to_hash(files)
  data = ""
  h    = {}

  # Load files 
  files.each {|fn| data << File.open(fn).read }

 # Gets the key values
  data.scan(/^([F3|R3]\w+): ([,\w]+)$/).each do |m| 
    key, value = m
    unless KEYS_PER_TAG.include?(key.gsub(/R3|F3/, "XX"))
      return "Invalid key found while processing stats"
    end
    h[key] = value
  end

  (h.size == 4 or h.size == 8) ?
  h :
  "Not the expected # of key/values: #{h.size}. Bailing out."
end

# Dump a line in the proper format
def dump_line(sea_dir, bams, stats)
  line = {}
  line[:name] = sea_dir.split("/")[-1]
  line[:start] = Helpers::start_end_time_output(sea_dir).split(",")[0]
  line[:end] = Helpers::start_end_time_output(sea_dir).split(",")[1]
  line[:ref] = Helpers::gather_meta_data(sea_dir).split(",")[0]
  line[:bfast] = Helpers::gather_meta_data(sea_dir).split(",")[1]
  line[:picard] = Helpers::gather_meta_data(sea_dir).split(",")[2]
  line[:mode] = Helpers::gather_meta_data(sea_dir).split(",")[3]
  line[:gatk] = Helpers::gather_meta_data(sea_dir).split(",")[4]
  line[:bam_path] = bams[0]
  tags = stats.size == 4 ? [ "F3" ] : [ "F3", "R3" ]
  tags.each do |tag|
    KEYS_PER_TAG.each do |k|
      key = k.gsub(/XX/, tag)
      if stats[key].nil?
        return "I cannot find key: #{key}, n_keys: #{stats.size}. Bye."
      end
      line[key] = stats[key].gsub(/,/,"")
    end
  end
  line
end

# Per each SEA, find the bams, the stats
# and dump a csv line with the data
def process_sea(path)
  bam   = find_bams(path)
  stats = find_stats_files(path)
  Helpers::log("Found BAMs: #{bam.size} STAT_FILEs: #{stats.size}")

  # Only process SEA if ...
  if bam.size == 1 and stats.size.to_s =~ /1|2/
    h_stats = to_hash(stats)
    if h_stats.is_a?(String)
		Helpers::log(h_stats)
    else
      if line = dump_line(path, bam, h_stats)
        return line
      end
    end
  else
    Helpers::log("Skipping #{path}")
  end
  false 
end

# returns the se name and start time
def sea_start(sea_dir)
  line = {}
  line[:name] = sea_dir.split("/")[-1]
  line[:start] = Helpers::start_end_time_output(sea_dir).split(",")[0]
  line
end

# Main
#
puts Dir.pwd

# grab the all of the stats
r_value = process_sea(Dir.pwd)

#grab the start time only
if ARGV[0] == "start"
  r_value = sea_start(Dir.pwd)
end

cmd = ""
if r_value != false
  cmd = "/hgsc_software/java/jdk1.6.0_05/bin/java -jar " +
        "/users/p-lims/programs/analysis-data/solid2Lims.jar put \""
  r_value.each do |k,v|
     cmd = cmd + "#{k}=#{v}&"
  end
  tmp = cmd.split("&")
  
  cmd = tmp.join("&") + "\""
  puts cmd
  system(cmd)
end 

