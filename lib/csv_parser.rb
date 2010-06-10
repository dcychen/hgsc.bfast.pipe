#!/usr/bin/ruby

$: << File.join("..", "lib")
require 'sequence_event'
require 'statistics'
require 'emailer'
require 'time_helpers'
require 'helpers'

class Csv_parser
  def initialize(path, email_to)
    if File.directory?(path)
      @all_csvs = parse_csv_list(find_csv(path))
      @email_to = email_to
      @today = TimeHelpers::TODAY
    else
      puts "The path does not exist"
      exit (1)
    end
  end

  def run
    email_from = "p-solid@bcm.edu"
    error_email_to = "dc12@bcm.edu"
    #email_to = [ "dc12@bcm.edu", "deiros@bcm.edu", "jgreid@bcm.edu", "pellon@bcm.edu"]

    yesterday = (Time.now - TimeHelpers::SECS_IN_DAY).strftime("%Y-%m-%d")
    yday = compare_today_with_day(@all_csvs, yesterday) 
    last_date = find_last_availabe_cycle_date(@all_csvs)
    accum = accumulate_tp(@all_csvs, last_date, @today)
#    if accum.tp < 1
#      Helpers::log("Error: The accumlated throughput for since Sunday is " +
#                   "less than 1")
 #     msg = "Error: the accumlated throughput for since Sunday is less than 1"
  #    @email_to = error_email_to
    if yday.new_tp < 0
      Helpers::log("Total throughput: #{yday.new_tp}")
      Helpers::log("Yesterday's throughput: #{yday.diff_tp}")
      msg = "Error: The total throughput is less than 0 (#{yday.new_tp})."
      @email_to = error_email_to
    else
      note = ""
      if yday.diff_tp < 0
        Helpers::log("Yesterday's throughput: #{yday.diff_tp}")
        msg = "The total throughput for today is less than the ones from " +
              "yesterday (#{yday.diff_tp})."
        Emailer::send_email(email_from, error_email_to, "SEA Error?", msg)
        note = "* a negative throughput for the day indicates removal and " +
               "restart of the SEAs which have failed at the steps after " + 
               "the SEA stats were generated.\n\n"

      end
      
      if accum.tp < 0 
        Helpers::log("Error: The accumulated throughput for since Sunday is " +
                   "less than 1")
        msg = "Error: the accumlated throughput for since Sunday is less than 1"
        Emailer::send_email(email_from, error_email_to, "SEA Error?", msg)
        note = "* a negative throughput indicates removal or restart of the " +
               "SEAs. \n\n"
      end

      week_failed_sea = []
      failed_sea.each do |f|
        if lingering_sea(f)
          week_failed_sea << f
        end
      end 

      failed = "#{week_failed_sea.size} lingering SEAs:\n" +
               week_failed_sea.join("\n").to_s
      msg = "Total:\nSEAs: #{yday.new_sea}\n" +
      "Throughputs: #{yday.new_tp} (" +
      "#{Statistics::round_to_two_dig(Statistics::to_tb(yday.new_tp.to_f))}" +
      "Tb)\n\nSEAs generated yesterday (#{yesterday}):\n" +
      "New SEAs: #{yday.diff_sea}\n" +
      "New throughputs: #{yday.diff_tp} (" +
      "#{Statistics::round_to_two_dig(Statistics::to_gb(yday.diff_tp.to_f))}" +
      "Gb)\n\n" +
      "From #{accum.date_pre} to #{accum.date_now}:\n" +
      "Generated SEAs: #{accum.sea}\n" +
      "Generated throughputs: #{accum.tp} " +
      "(#{Statistics::round_to_two_dig(Statistics::to_gb(accum.tp.to_f))}Gb)" +
      "\n\n" + note + failed
    end

    Emailer::send_email(email_from, @email_to, "SEA updates", msg)

    #to_csv(total, "csv_data.csv")
    #check_parsed_list(total)
  end

  # goes through each sea and determines which sea has failed
  def failed_sea(csv = today_csv)
    log = File.dirname(csv) + "/" + File.basename(csv,".csv") + ".log"
    failed = []
    File.open(log, "r").each do |f|
      if /Skipping/.match(f)
        sea = Sequence_event.new(f.split()[2].chomp)
        if !sea.job_in_cluster?
          sea_path = Helpers::dir_exists?(sea)[0]
          if !sea_path.nil?
            failed << sea_path 
          end
        end
      end
    end
    failed
  end

  # goes through the failed sea and checks the ones that have been 
  # there for over a week
  def lingering_sea(sea_path)
    last_mod_time = File.mtime(sea_path)
    seven_days_prior = Time.now - (TimeHelpers::SECS_IN_DAY * 7)
    if seven_days_prior < last_mod_time
      return FALSE
    end
    TRUE  
  end

  # returns the path of csv created today
  def today_csv
    if @all_csvs.key?(@today)
      @all_csvs[@today][2]
    else
      "today's csv is not found"
    end
  end
  
  #finds all of the csv from the given path
  def find_csv(path)
    csv = []
    Find.find(path) do |f|
      if File.file?(f)
        if /csv$/.match(f) && !/latest/.match(f)
          csv << f
        end
      end
    end
    csv
  end

  def csv_total_throughputs(csv)
    throughputs = 0
    File.open(csv, "r").each do |l|
      next if /throughput/.match(l)
      temp = l.split(",")
      throughputs = throughputs + temp[6].gsub('.','').to_i
      if !temp[10].nil?
        throughputs = throughputs + temp[10].gsub('.','').to_i
      end
    end
    throughputs
  end

  #grabs the total about of sea entries in the csv file
  def sea_amount(csv)
    File.open(csv,"r").readlines.size - 1
  end

  #parse the date from the csv file name
  def grab_date(csv)
    csv.split(".")[2]
  end

  def compare_today_with_day(csv_list, day)
    if csv_list.key?(day) && csv_list.key?(@today)
      diff = diff_in_day(csv_list[@today], csv_list[day])
      return diff
    else
      puts "required csv(s) are not present"
      exit(1)
    end
  end

  def find_next_available_date(csv_list, date_start)
    if !csv_list.key?(date_start)
      entry_start_date = TimeHelpers::return_date_obj(date_start).next
      while !csv_list.key?(entry_start_date.to_s)
        entry_start_date = entry_start_date.next
      end
      entry_start_date.to_s
    else
      date_start
    end
  end

  #return the last available date in case the entry for Sudnay is not avilable
  def find_last_availabe_cycle_date(csv_list)
    last_sun = TimeHelpers::last_sun_date
    find_next_available_date(csv_list, last_sun)
  end

  #goes through the list and constructs hash of the stats
  def parse_csv_list(csvs)
    temp = {}
    csvs.each do |c|
      temp[grab_date(c)] = [sea_amount(c), csv_total_throughputs(c), c]
    end
    temp
  end

  #ouputs the contents of the parsed csv_list
  def check_parsed_list(parsed_list)
    parsed_list.sort.each do |k,v|
      string = ""
      v.each do |val|
        string = string + " " + val.to_s
      end
      puts "#{k}: #{string}"
    end
  end

  #outputs the parsed list to a csv file
  def to_csv(data, file)
    f = File.open(file,"w")
    data.each do |k,v|
      temp = ""
      v.each { |val| temp = temp +",#{val}"}
      f.puts "#{k},#{temp}"
    end
    f.close
  end

  private

  # calculates the throughput since last Sunday, or the one closeest to last Sunday
  def accumulate_tp(csv_list, old_date, new_date)
    diff = diff_in_day(csv_list[new_date], csv_list[old_date])
    temp = OpenStruct.new
    temp.date_pre = old_date
    temp.date_now = new_date
    temp.sea = diff.diff_sea
    temp.tp = diff.diff_tp
    temp
  end

  #calculates the differences in sea and throughputs with the given two days
  def diff_in_day(new, old)
    temp = OpenStruct.new
    temp.new_sea  = new[0]
    temp.new_tp   = new[1]
    temp.old_sea  = old[0]
    temp.old_tp   = old[1]
    temp.diff_sea = new[0] - old[0]
    temp.diff_tp  = new[1] - old[1]
    temp
  end
end
