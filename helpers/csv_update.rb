#!/usr/bin/ruby
# ARGV[0] - path to where the csv is stored
# ARGV[1] - email or email list
#
# Author: David Chen


$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'helpers'
require 'time'
require 'csv_parser'

if File.directory?(ARGV[0])
  Helpers::log("Start: #{Time.now}")
  csv = Csv_parser.new(ARGV[0], ARGV[1].split)
  csv.run
  Helpers::log("Finished: #{Time.now}")
else
  Helpers::log("Cannot find the directory",1)
end
