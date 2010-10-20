#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
require 'time'
require 'ostruct'
require 'date'

module TimeHelpers
  SECS_IN_DAY = 86400
  TODAY = Date.today.to_s

  # @params: time1: Time object
  #          time2: Time object
  # returns: boolean - true if same day, else false
  def self.same_day(time1, time2)
    return time1.strftime("%F") == time2.strftime("%F")
  end

  # @params: start: Time , finish: Time 
  # returns: integer - seconds took from start to finish 
  def self.time_lapsed(start, finish)
    return finish - start
  end
 
  # returns: last month in the following format yyyy-mm 
  def self.get_pre_mon
    mon = Date.today.month
    year  = Date.today.year
    if mon == 1
      year = year - 1
      mon = 12
    else
      mon = mon - 1
      if mon < 10
        mon = "0" + mon.to_s
      end
    end
    return year.to_s + "-" +  mon.to_s
  end

  # @params: start: String , finish: String
  #          format can be as following:
  #          Started at Sat Apr  3 07:52:38 2010 ||
  #          Sat Apr  3 07:52:38 2010 ||
  #          Apr  3 07:52:38 2010
  #
  # ie. Started at Sat Apr  3 07:52:38 2010
  #     Results reported at Sat Apr  3 08:03:27 2010
  #
  # returns: Time object
  def self.string_to_time(line)
    temp = parse_date_time(line)
    Time.local(temp.year, temp.mon, temp.day,
               temp.hour, temp.min, temp.sec)
  end

  # @params: date: String - yyyy-mm-dd
  #           am_pm: String - am || pm
  # returns: Time object -  
  #           case "am" - same date at 12 am
  #           case "pm" - same date at 11:59 pm 
  #2010-05-10, am => 05 10 00:0:0 2010
  #2010-05-10, pm => 05 10 23:59:59 2010
  def self.create_time_from_date(date, am_pm)
    date_split = date.split("-")
    time = ""
    if am_pm == "am"
      time = parse_time("00:0:0")
    else
      time = parse_time("23:59:59")
    end
    Time.local(date_split[0], date_split[1], date_split[2],
              time.h, time.m, time.s)
  end
  
  # @params: start : String - yyyy-mm-dd
  #          finish: String - yyyy-mm-dd
  # returns: Array of the dates, inclusively  
  #
  # ie: start =  2010-04-03 finish = 2010-04-05
  #    output = ["2010-04-03", "2010-04-04", "2010-04-05"]
  def self.range_of_intervals(start, finish)
    temp = []
    interval_st = create_time_from_date(start,"am")
    interval_fi = create_time_from_date(finish,"am")
    interval_tmp = interval_st
    while interval_tmp <= interval_fi
      temp << interval_tmp.strftime("%F")
      interval_tmp = interval_tmp + SECS_IN_DAY
    end
    temp
  end

  #helper method that returns last sunday's date
  def self.last_sun_date()
    day = ""
    date = Time.now
    while day != "Sun"
      date = date - SECS_IN_DAY
      day = date.strftime("%a")
    end
    date.strftime("%Y-%m-%d")
  end

  def self.return_date_obj(date)
    temp_split = split_date(date)
    Date.new(temp_split.year, temp_split.month, temp_split.day)
  end


  private

  def self.split_date(entry_date)
    temp = OpenStruct.new
    temp.year = entry_date.split("-")[0].to_i
    temp.month = entry_date.split("-")[1].to_i
    temp.day = entry_date.split("-")[2].to_i
    temp
  end

  # @param: line: String
  #         format can be as following:
  #          Started at Sat Apr  3 07:52:38 2010 ||
  #         Sat Apr  3 07:52:38 2010 ||
  #         Apr  3 07:52:38 2010
  #
  # ie. Started at Sat Apr  3 07:52:38 2010
  #     Results reported at Sat Apr  3 08:03:27 2010
  #
  # returns: OpenStruct object - parsed year, mon (month), day, hour, min, sec
  def self.parse_date_time(line)
    line_split = line.split()
    time = parse_time(line_split[line_split.size - 2])
    temp = OpenStruct.new
    temp.year  = line_split.last.to_i
    temp.mon   = line_split[line_split.size - 4]
    temp.day   = line_split[line_split.size - 3]
    temp.hour  = time.h
    temp.min   = time.m
    temp.sec   = time.s
    temp
  end

  # @params: time: String
  #          format as hh:mm:ss
  # returns: OpenStruct object - parsed h (hour), m (minute), s (seconds)
  def self.parse_time(time)
    time_split = time.split(":")
    temp = OpenStruct.new
    temp.h = time_split[0].to_i
    temp.m = time_split[1].to_i
    temp.s = time_split[2].to_i
    temp
  end
end
