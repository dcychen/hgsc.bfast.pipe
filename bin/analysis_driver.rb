#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# Main entry point to perform bfast analysis 
#
# Author: David Rio Deiros

require 'optparse' 
require 'ostruct'
require 'date'
require 'logger'

$: << File.join(File.dirname(File.dirname($0)), "lib")
require 'load_libs'

#
class App
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments     = arguments
    @stdin         = stdin
    @valid_actions = /(create|remove)/
    main_dir = File.dirname(File.dirname(__FILE__))
    $config = Helpers::load_config_file("#{main_dir}/etc/config.yaml")

    # Set defaults
    @options         = OpenStruct.new
    # TO DO - add additional defaults
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
      opts.on('-v', '--version')        { output_version ; exit 0 }
      opts.on('-h', '--help')           { output_help }

      opts.on('-r', '--run_name  r')    {|r| @options.run_name = r }
      opts.on('-c', '--c_design  c')    {|c| @options.c_design = c }
      opts.on('-q', '--queue     q')    {|q| @options.queue    = q }
      opts.on('-a', '--action    a')    {|a| @options.action   = a }
      opts.on('-f', '--reference f')    {|f| @options.ref      = f }
      opts.on('-m', '--force_mp')       {    @options.force_mp = true }
      opts.on('-e', '--force_pe')       {    @options.force_pe = true }
      opts.on('-n', '--no_trans_check') {    @options.no_trans_check = true }
      opts.on('-s', '--special_run')    {    @options.special_run = true }
      opts.on('-p', '--pival p')        {|p| @options.pival    = p.upcase }
      opts.on('--no_rg'   )             {    @options.no_rg = "true" }
      opts.on('--rg_lb       l')        {|l| @options.rg_lb    = l }
      opts.on('--rg_sm       s')        {|s| @options.rg_sm    = s }

      log "Processing arguments"
      opts.parse!(@arguments) rescue return false
      if ! @options.pival.nil? and ! %w(STRICT LENIENT SILENT).include?(@options.pival)
          log "Invalid picard validation string"
          return false
      end
      log "Parsing options"
      process_options
      true
    end

    # Performs post-parse processing on options
    def process_options
    end
    
    def output_options
      @options.marshal_dump.each {|name, val| log "#{name} = #{val}" }
    end

    # True if required arguments were provided
    def arguments_valid?
      true
    end

    # Place arguments in instance variables
    def process_arguments
      @r_name         = @options.run_name
      @sea            = @r_name.nil? ? nil : Sequence_event.new(@r_name)
      @c_design       = @options.c_design || nil
      @queue          = @options.queue    || "normal"
      @ref            = @options.ref      || $config["h18_ref"]
      @action         = @options.action
      @force_mp       = @options.force_mp || false
      @force_pe       = @options.force_pe || false
      @no_trans_check = @options.no_trans_check || false
      @special_run    = @options.special_run || false
      @no_rg          = @options.no_rg || "false"
      @pival          = @options.pival || "STRICT"
      @rg_lb          = @options.rg_lb || "unknown"
      @rg_sm          = @options.rg_sm || "unknown"
      log "picard validation mode: #{@pival}"
      log "Forcing MP mode detected" if @force_mp
      log "Forcing PE mode detected" if @force_pe
      log "No transfer file check detected" if @no_trans_check


      # parameters for the bf.config.yaml file
      @java           = $config["java"]
      @bfast          = $config["bfast"]["path"]
      @bfast_version  = $config["bfast"]["version"]
      @picard         = $config["picard"]["path"]
      @picard_version = $config["picard"]["version"]
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
      Driver_actions.new(@action).get_action.run(params_to_hash)
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
        :r_name         => @r_name  ,
        :c_design       => @c_design,
        :queue          => @queue   ,
        :action         => @action  ,
        :sea            => @sea     ,
        :force_mp       => @force_mp,
        :force_pe       => @force_pe,
        :no_trans_check => @no_trans_check,
        :special_run    => @special_run,
        :ref            => @ref,
        :pival          => @pival,
        # params for bf.config.yaml       
        :java           => @java,
        :bfast          => @bfast,
        :bfast_version  => @bfast_version,
        :picard         => @picard,
        :picard_version => @picard_version,
        :no_rg          => @no_rg,
        :rg_lb          => @rg_lb,
        :rg_sm          => @rg_sm,
      }
    end

    def log(msg)
      Helpers::log msg.chomp
    end

    def error(msg)
      $stderr.puts "ERROR: " + msg + "\n\n"; output_usage; exit 1
    end
end

# Create and run the application
app = App.new(ARGV, STDIN)
app.run

__END__
Usage:
  analysis_driver.rb [options]

Options:
 -h, --help           Displays help message
 -v, --version        Display the version, then exit

 -r, --run_name       Run_name
 -a, --action         action to perform 

 -f, --reference      path of the reference
 -m, --force_mp       Force MP despite the SE is a PE
 -e, --force_pe       Force PE despite the SE is a FR
 -n, --no_trans_check Force analysis without checking raw data transfer
 -s, --special_run    Look into the special directories
 -c, --c_design       capture_design
 -q, --queue          cluster queue     [normal]
 -p, --pival          Picard validation [STRINGENT] (STRICT|LENIENT|SILENT)

 --no_rg              turn off rg tags
 --rg_lb              library name
 --rg_sm              sample name

Valid actions:
 create: create the analysis dir and config file
         $ analysis_driver.rb -a sea_create -r RUN -f reference
         $ analysis_driver.rb -a sea_create -r RUN -f reference -c C_DESIGN_DIR

 remove: check if analysis exists
         $ analysis_driver.rb -a sea_remove -r RUN
