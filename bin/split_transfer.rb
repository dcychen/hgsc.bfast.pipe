#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# Entry point to manage data transfers from the sequencing machines
#
# Author Phillip Coleman

require 'optparse' 
require 'ostruct'
require 'date'
require 'logger'
require 'yaml'
require 'pp'
require 'socket'

main_dir = File.dirname(File.dirname(__FILE__))

require main_dir + "/lib/t_actions.rb"
require main_dir + "/lib/helpers.rb"

#
class TransferApp
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments     = arguments
    @stdin         = stdin
    @valid_actions = /(ping|list_se|disk_usage|se_ready|transfer|completed_se|stop)/

    # Set defaults
    @options         = OpenStruct.new
  end

  # Parse options, check arguments, then process the command
  def run
    if parsed_options? && arguments_valid?
      log "Start at #{DateTime.now}\n"
      output_options

      process_arguments
      process_command
      log "Finished at #{DateTime.now}"
    else
      output_usage
    end
  end
  
  protected

    def parsed_options?
      # Specify options
      opts = OptionParser.new 
      opts.on('-v', '--version')      { output_version ; exit 0 }
      opts.on('-h', '--help')         { output_help }
      opts.on('-l', '--all')          { load_machine_list }
      opts.on('-m', '--machine_names m') { |m| load_machine_name(m) }
      opts.on('-a', '--action   a')   {|a| @options.action   = a }
      opts.on('-r', '--run r')        { |r| load_runs(r) }
      opts.on('-e', '--email e')      { |e| load_email(e) }  
      opts.on('-s', '--snfs s')       { |s| @options.snfs = s }   

      log "Processing arguments"
      opts.parse!(@arguments) rescue return false
      log "Parsing options"
      process_options
      true
    end

    # Performs post-parse processing on options
    def process_options
      if @options.machine_names == nil
        load_machine_list
      end
    end
    
    def output_options
      @options.marshal_dump.each {|name, val| log "#{name} = #{val}" }
    end

    # True if required arguments were provided
    def arguments_valid?
      ret = false
      ret = true unless (@options.action == nil)
    end

    # Place arguments in instance variables
    def process_arguments
      @e_addr   = @options.email
      @r_name   = @options.run_names
      @m_name   = @options.machine_names
      @action   = @options.action
      @snfs     = @options.snfs
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      puts DATA.read
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      error "Not valid action" unless @action =~ @valid_actions
      Transfer_actions.new(@action).get_action.run(params_to_hash)
    end

    def process_standard_input
      input = @stdin.read      
      # TO DO - process input
      
      # @stdin.each do |line| 
      #  # TO DO - process each line
      #end
    end

    def params_to_hash
      {
        :e_addr   => @e_addr  ,
        :r_name   => @r_name  ,
        :m_name   => @m_name  ,
        :action   => @action  ,
	:snfs     => @snfs    ,
      }   
    end

    def load_machine_list
      name = Socket.gethostname
      list_file = File.dirname(File.dirname(__FILE__)) +
                  "/etc/split.machine_list.yaml" 
      obj = ""
      File.open(list_file, "r") do |infile|
        while (line = infile.gets)
          obj << line
        end
      end
      list = YAML::load(obj)
      if (name == "stornext7")
        @options.machine_names = list['stornext7']
      else
        @options.machine_names = list['sug-backup'] 
      end
    end

    def load_machine_name(names)
     
      
      list_file = File.dirname(File.dirname(__FILE__)) + "/etc/machine_list.yaml"
      obj = ""
      File.open(list_file, "r") do |infile|
        while (line = infile.gets)
          obj << line
        end
      end
      
      list = YAML::load(obj)
      list = list['machine_addresses'] 
      newlist = names.split
      hash = Hash.new
      newlist.each do |n|
        hash[n] = list[n]
      end
      @options.machine_names = hash
    end

    def load_runs(r)
      names = r.split
      @options.run_names = names
    end

    def load_email(e)
      email = e.split
      @options.email = email
    end

    def log(msg)
      Helpers::log msg.chomp
    end

    def error(msg)
      $stderr.puts "ERROR: " + msg + "\n\n"; output_usage; exit 1
    end
end

# Create and run the application

app = TransferApp.new(ARGV, STDIN)
app.run

__END__
Usage: 
  analysis_driver.rb [options]

Options:
 -h, --help                             Displays help message
 -v, --version                          Display the version, then exit

 -m, --machine_name, --machine_names,   Machine_names
 -l, --all                              loads alls machines
 -a, --action                           action to perform 
 -e, --email                            list of emails to be notified
 -s, --snfs                             the snfs server to transfer to



Valid actions:
 ping: pings specified servers and lists their statuses
       $ transfer_driver.rb -a ping -m solid0044
       $ transfer_driver.rb -a ping -m "solid0044 solid0097"
       $ transfer_driver.rb -a ping -l
 
 list_se: Lists the sequence events on the specified machines
       $ transfer_driver.rb -a list_se -m solid0044 [-r 0044_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1]
       $ transfer_driver.rb -a list_se -m "solid0044 solid0097" [-r 0097_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1]
       $ transfer_driver.rb -a list_se -l
       $ transfer_driver.rb -a list_se -r 0708_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1 
  
 disk_usage: Lists the amount of free space and the percentage of space used on the specified machines
       $ transfer_driver.rb -a disk_usage -m solid0044 -e name@domain.com
       $ transfer_driver.rb -a disk_usage -m "solid0044 solid0097" -e "name@domain.com name2@domain.com"
       $ transfer_driver.rb -a disk_usage -l -e "name@domain.com"
       $ transfer_driver.rb -a disk_usage -e "name@domain.com"

 se_ready: Checks to see if the sequence has finished transfering
       $ transfer_driver.rb -a se_ready -r 0044_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1

 transfer: transfers all the data files for a given machine and run
       $ transfer_driver.rb -a transfer -m solid0044 -s 4 -r 0044_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1 -e "name@domain.com"
       $ transfer_driver.rb -a transfer -m solid0044 -s 4 -e "name@domain.com"

 complete_se: Places the slide done flag in the appropriate directory based off the run name
       $ transfer_driver.rb -a completed_se -r 0044_20100601_2_SL_ANG_OIVBL_189_01_02_1_1sA_01003311222_1 
       $ transfer_driver.rb -a completed_se -r 0044_20100601_2_SL 

 stop: Stops all transfers from the specified machines
       $ transfer_driver.rb -a stop -m solid0044
       $ transfer_driver.rb -a stop -m "solid0044 solid0097"
       $ transfer_driver.rb -a stop -l
       $ transfer_driver.rb -a stop
