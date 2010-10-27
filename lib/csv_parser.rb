#!/usr/bin/ruby

$: << File.join("..", "lib")
require 'sequence_event'
require 'statistics'
require 'emailer'
require 'time_helpers'
#require 'helpers'
#
class Csv_parser
  def initialize(path, email_to)
    @theCSV = path+"csv.dump.latest.csv"
    if File.exists?(@theCSV)
      #{EndTime:[<#lines || amount>, <throughput total>, <filename>, <time>]}
      @all_csvs = parse_csv_list(find_csv(path))
      @email_to = email_to
      @today = TimeHelpers::TODAY
    else
	puts "The latest dump could not be found in specified path"
	exit
    end
  end

  def run
    email_from = "p-solid@bcm.edu"
    error_email_to = "english@bcm.edu" #Temporary Disabling "dc12@bcm.edu"
 	#Day csv name format 
	#	csv.dump.YYYY-MM-DD.HH:MM:SS.csv
    
    
    today =  DateTime::parse((Time.now).strftime("%Y-%m-%d"))
    yesterday =  DateTime::parse((Time.now - TimeHelpers::SECS_IN_DAY).strftime("%Y-%m-%d") )
    
    #Work around so that on sundays, it looks for last sunday 
    #This should make a sunday's report be a full week report
    sunday = DateTime::parse(TimeHelpers::last_sun_date)
	
	#[<#lines || amount>, <throughput total> ] #
	yday_total = [0, 0]
	week_total = [0, 0]
	all_total = [0, 0]
	
	#Add each stat to whichever day's totals it contributes to
	fh = File.new(@theCSV, 'r')
	line = fh.gets#Header
	while (line = fh.gets)
		data = line.split(',')
		endTime = Date::strptime(data[2].split('_')[0],"%m/%d/%y")
		throughput = sea_throughputs(line)
		if today >= endTime and endTime >= yesterday
			yday_total[0] += 1
			yday_total[1] += throughput
		end
		
		if endTime >= sunday
			week_total[0] += 1
			week_total[1] += throughput
		end
		
		all_total[0] += 1
		all_total[1] += throughput
		
    	end
   	
   	week_failed_sea = []
   	failed_sea.each do |f|
   		if lingering_sea(f)
   			week_failed_sea << f
   		end
   	end
   	
   	failed = "#{week_failed_sea.size} lingering SEAs:\n" + week_failed_sea.join("\n").to_s
   			
    msg = "Total:\nSEAs: #{all_total[0]}\n" +
      "Throughputs: #{all_total[1]} (#{Statistics::round_to_two_dig(Statistics::to_tb(all_total[1].to_f))}Tb)\n" +
      "\n"+
      "SEAs generated yesterday (#{yesterday.strftime("%Y-%m-%d")}):\n"+
      "New SEAs: #{yday_total[0]}\n" +
      "New throughputs: #{yday_total[1]} (#{Statistics::round_to_two_dig(Statistics::to_gb(yday_total[1].to_f))}Gb)\n" +
      "\n" + 	
      "From #{sunday.strftime("%Y-%m-%d")} to #{today.strftime("%Y-%m-%d")}:\n" +
      "Generated SEAs: #{week_total[0]}\n" +
      "Generated throughputs: #{week_total[1]} " +
      "(#{Statistics::round_to_two_dig(Statistics::to_gb(week_total[1].to_f))}Gb)" +
      "\n\n" + failed
      
      
    Emailer::send_email(email_from, @email_to, "SEA updates", msg)

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
    #Automatic Recursion all the way down
    #This grabs all the csvs except latest
    Find.find(path) do |f|
      if File.file?(f)
        if /csv$/.match(f) && !/latest/.match(f)
          csv << f
        end
      end
    end
    csv
  end

  def sea_throughputs(l)
    throughputs = 0
    temp = l.split(",")
    #Grabbing the F throughput
    throughputs = throughputs + temp[6].gsub('.','').to_i
    #If there is a R throughput, grab it
    if !temp[10].nil?
      throughputs = throughputs + temp[10].gsub('.','').to_i
    end
    
    throughputs
  end

  def csv_total_throughputs(csv)
    throughputs = 0
    File.open(csv, "r").each do |l|
      next if /throughput/.match(l)
      	throughputs += sea_throughputs(l)
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
#puts csv_list[@today]
#puts csv_list[day]
#puts csv_list.class
#puts @today
#puts day
#exit(1)

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

  #returns the time when the csv is crated
  def get_csv_time(csv_name)
    temp = csv_name.split(".")
    return temp[-2]
  end

  #goes through the list and constructs hash of the stats
  def parse_csv_list(csvs)
     #Structure {Date:[<#lines || amount>, <throughput total>, <filename>, <time>]}
     #Date and time are from filename
    temp = {}
    csvs.each do |c|
      date = grab_date(c)
      time = get_csv_time(c)
      if temp.include?(date)
        if temp[date][3] > time
          temp[date] = [sea_amount(c), csv_total_throughputs(c), c, get_csv_time(c)]
        end
      else
        temp[date] = [sea_amount(c), csv_total_throughputs(c), c, get_csv_time(c)]
      end        
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
    temp.diff_sea = new[0] - old[0]
    temp.diff_tp  = new[1] - old[1]
    temp
  end
end
