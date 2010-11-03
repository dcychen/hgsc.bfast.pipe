#!/usr/bin/ruby
#
# Author: David Chen & Adam English

$: << File.join("..", "lib")
require 'sequence_event'
require 'statistics'
require 'emailer'
require 'time_helpers'

class Csv_parser
  def initialize(path, email_to)
    @thePath = path+'/'
    if File.exists?(@thePath)
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
    error_email_to = "dc12@bcm.edu"
    #Day name format 
    #csv.dump.YYYY-MM-DD.HH:MM:SS.csv
    today =  DateTime::parse((Time.now).strftime("%Y-%m-%d"))
    yesterday =  DateTime::parse((Time.now - TimeHelpers::SECS_IN_DAY).strftime("%Y-%m-%d") )

    #Work around so that on sundays, it looks for last sunday 
    #This should make a sunday's report be a full week report
    sunday = DateTime::parse(TimeHelpers::last_sun_date)

    #[<#lines || amount>, <throughput total> ] #
    yday_total = [0, 0]
    week_total = [0, 0]
    all_total = [0, 0]
    #For tracking what's been removed (next step)
    latest_seas = {} # Name:endDate

    #Add each stat to whichever day's totals it contributes to
    fh = File.open(@thePath+"csv.dump.latest.csv", 'r')
    line = fh.gets#Header
    while (line = fh.gets)
      data = line.split(',')
      latest_seas[data[0]] = data[2]
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
     
    totals_msg = "Total:\nSEAs: #{all_total[0]}\n" +
            "Throughputs: #{all_total[1]} " +
            "(#{Statistics::round_to_two_dig(Statistics::to_tb(all_total[1].to_f))}Tb)\n" +
            "\n"+
            "SEAs generated yesterday (#{yesterday.strftime("%Y-%m-%d")}):\n"+
            "New SEAs: #{yday_total[0]}\n" +
            "New throughputs: #{yday_total[1]} "+
            "(#{Statistics::round_to_two_dig(Statistics::to_gb(yday_total[1].to_f))}Gb)\n" +
            "\n" +
            "From #{sunday.strftime("%Y-%m-%d")} to #{today.strftime("%Y-%m-%d")}:\n" +
            "Generated SEAs: #{week_total[0]}\n" +
            "Generated throughputs: #{week_total[1]} " +
            "(#{Statistics::round_to_two_dig(Statistics::to_gb(week_total[1].to_f))}Gb)"
    #Calculating the removed information
    removed = [0, 0]
    best_date = today
    yday_path = @thePath + yesterday.strftime("%Y/%m/%d/")
    yday_csv = ""  
    #Find yesterday's file
    Find.find(yday_path) do |f|
      if File.file?(f) and /csv$/.match(f)
        f_date = DateTime::strptime(f.split('/')[-1][9,19], "%Y-%m-%d.%H:%M:%S") # parse out date file date
        if f_date < best_date #Get the earliest file
          yday_csv = f
          best_date = f_date
        end
      end
    end

    #Parse Yesterday's File
    fh = File.open(yday_csv, 'r')
    line = fh.gets #header
    while (line = fh.gets)
      data = line.split(',')
      todayData = latest_seas[data[0]] #this sea's information from today 
      if todayData == nil or todayData != data[2] #a removed or an updated sea
        removed[0] += 1
        removed[1] += sea_throughputs(line)
      end
    end

    removed_msg = "Removed or Updated SEAs: #{removed[0]} "+
                  "(#{Statistics::round_to_two_dig(Statistics::to_gb(removed[1].to_f))}Gb)"

    #Calculating the failed seas  
    week_failed_sea = []
    failed_sea.each do |f|
      if lingering_sea(f)
        week_failed_sea << f
      end
    end
    failed = "#{week_failed_sea.size} lingering SEAs:\n" + week_failed_sea.join("\n").to_s
    msg = totals_msg + "\n\n" + removed_msg + "\n\n" + failed
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
      @all_csvs[@today][0]
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

  #parse the date from the csv file name
  def grab_date(csv)
    csv.split(".")[2]
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
        if temp[date][1] > time
          temp[date] = [c, get_csv_time(c)]
        end
      else
        temp[date] = [c, get_csv_time(c)]
      end
    end
    temp
  end
end
