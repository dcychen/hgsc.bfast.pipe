#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80 
# 
# Author: David Chen

require 'optparse' 
require 'ostruct'
require 'date'
require 'logger'
require 'yaml'
require 'fileutils'

$: << File.join(File.dirname(File.dirname($0)), "lib")
require 'helpers'
require 'm_actions'
require 'moab_dealer'

#
class MuApp
  VERSION = '1.0.0'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments   = arguments
    @stdin       = stdin
    @options     = OpenStruct.new
    main_dir = File.dirname(File.dirname(__FILE__))
    $config = Helpers::load_config_file("#{main_dir}/etc/config.yaml")
  end

  # Parse options, check arguments, then process the command
  def run
    if parsed_options? && arguments_valid?
      log "Start at #{DateTime.now}\n"
      output_options
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
    opts.on('-v', '--version')  { output_version ; exit 0 }
    opts.on('-h', '--help')     { output_help }

    opts.on('--merge'    )   { @options.merge     = TRUE }
    opts.on('--dups'     )   { @options.dups      = TRUE }
    opts.on('--cap_dup'  )   { @options.cap_dup   = TRUE }
    opts.on('--cap_nodup')   { @options.cap_nodup = TRUE }
    opts.on('--snps'     )   { @options.snps      = TRUE }   
    opts.on('--all'      )   { @options.all       = TRUE }

    opts.on('--rg'     )     { @options.rg        = TRUE }

    opts.on('-p', '--project  p')  { |p|   @options.project  = p }
    opts.on('-s', '--sub_dir  s')  { |s|   @options.sub_dir  = s }
    opts.on('-c', '--c_design c')  { |c|   @options.c_design = c }
    opts.on('-o', '--outname  o')  { |o|   @options.outname  = o }
    opts.on('-b', '--bams     b')  { |b|   @options.bams     = b }
    opts.on('-q', '--queue    q')  { |q|   @options.queue    = q }
    opts.on('-d', '--outdir   d')  { |d|   @options.outdir   = d }
    opts.on('-l', '--config   l')  { |l|   @options.config   = l }
    opts.on('--hg18'            )  {       @options.ref      = "hg18" }
    opts.on('--rg_id rg_id'     )  {|rg_id|@optiosn.rg_id    = rg_id }
    opts.on('--sample samp'     )  {|samp| @options.sample   = samp }
    log "Processing arguments"
    opts.parse!(@arguments) rescue return false
    log "Parsing options"
#      process_options
    process_arguments
    true
  end

  def process_options
#		puts @options.marshal_dump
  end

  def output_options
    @options.marshal_dump.each {|name, val| log "#{name} = #{val}" }
  end

  # True if required arguments were provided
  def arguments_valid?
     true 
     # to do
  end

  # Place arguments in instance variables
  def process_arguments
    if @options.config != nil
      if File.exist?(@options.config)
        load_config_file 
        @config.each do |k, v|
          @project = v

#need to do 

        end
      else
        error("Config file does not exist")
      end
    else
      @project    = @options.project  || "NA"
      @sub_dir    = @options.sub_dir  || "NA"
      @outname    = @options.outname  || @options.sub_dir
      @outdir     = @options.outdir   || $config["outdir"]
      @bams       = @options.bams
      @c_design   = @options.c_design || nil
      @queue      = @options.queue    || $config["queue"]
      @ref        = @options.ref || "hg19"
      @rg_id      = @options.rg_id || $config["rg"]["rg_id"]
      @sample     = @options.sample || "NA"

    end
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
    # checks if a valid action is given 
    check = FALSE
    valid_actions = [ @options.merge, @options.dups, @options.cap_dup,
                      @options.cap_nodup, @options.snps, @options.all,
                      @options.rg ]
    valid_actions.each do |x|
      if x == TRUE
        check = TRUE
      end
    end

    error "Not valid action" unless check

    outdir = @outdir + "/" + @project + "/" + @sub_dir
    FileUtils.mkpath("#{outdir}/moab_logs")
    run_file = "#{outdir}/run_mu.sh"
    if File.exists?(run_file)
      FileUtils.rm(run_file)
    end
     
    dep = "" 

    if @options.rg
      mu_cmd = Mu_actions.new("rg").get_action.run(params_to_hash)
      moab(run_file, "#{@outname}.rg_fix", mu_cmd[0], @queue, mu_cmd[1], "")
    end
    if @options.all || @options.merge
      mu_cmd = Mu_actions.new("merge").get_action.run(params_to_hash)
      dep = moab(run_file, "#{@outname}.merge", mu_cmd[0], @queue, mu_cmd[1], "")
    end
    if @options.all || @options.dups
      params = params_to_hash
      if @options.merge || @options.all
        params[:bams] = "#{outdir}/#{@outname}.merged.bam"
      end
      mu_cmd = Mu_actions.new("dups").get_action.run(params)
      dep = moab(run_file, "#{@outname}.dups", mu_cmd[0], @queue, mu_cmd[1], dep)
    end
    final = ""
    if @options.all || @options.cap_dup
      params = checking_input(params_to_hash, outdir)
      mu_cmd = Mu_actions.new("cap_dup").get_action.run(params)
      final = final + ":" + moab(run_file, "#{@outname}.cap_dup", mu_cmd[0], @queue, mu_cmd[1], dep)
    end
    if @options.all || @options.cap_nodup
      params = checking_input(params_to_hash, outdir)
      mu_cmd = Mu_actions.new("cap_nodup").get_action.run(params)
      final = final + ":" + moab(run_file, "#{@outname}.cap_nodup", mu_cmd[0], @queue, mu_cmd[1], dep)
    end
    if @options.all || @options.snps
      params = checking_input(params_to_hash, outdir)
      mu_cmd = Mu_actions.new("snps").get_action.run(params)
      moab(run_file, "#{@outname}.snps", mu_cmd[0], @queue, mu_cmd[1], dep)
    end
    Dir.chdir(outdir)
    
    # submits the job
    system("sh #{run_file}")
  end

  def checking_input(params, out)
    temp = params_to_hash
    if @options.merge
        temp[:bams] = "#{out}/#{@outname}.merged.bam"
    elsif @options.dups || @options.all
      temp[:bams] = "#{out}/#{@outname}.dups.bam"
    end
    return temp
  end

  def moab(out_script, name, job, queue, mem, dep)
    File.open(out_script, "a") do |w|
      w.puts("echo ##{name}")
      w.puts("echo \"#{job}\" | \\")
      w.puts("msub -d `pwd` -V -q #{queue} \\")
      w.puts("-o moab_logs/#{name}.o -e moab_logs/#{name}.e \\")
      if dep != ""
        w.puts("-l depend=afterok:#{dep} \\")
      end
      w.puts("-l 'mem=#{mem}mb' -N #{name}" )
      w.puts ""
    end
    return name
  end

  def params_to_hash
    {
      :project    => @project ,
      :c_design   => @c_design,
      :queue      => @queue   ,
      :sub_dir    => @sub_dir ,
      :outname    => @outname ,
      :outdir     => @outdir  ,
      :bams       => @bams    ,
      :ref        => @ref     ,
      :rg_id      => @rg_id   ,
      :sample     => @sample  ,
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
app = MuApp.new(ARGV, STDIN)
app.run

__END__
Usage:
 mu_driver.rb [options]

Options:
 -h, --help           Displays help message
 -v, --version        Display the version, then exit

 Actions
 --merge              merges the bams together
 --dups               marks duplicate reads on the given bam
 --cap_dup            calls capture stats with duplicates
 --cap_nodup          calls capture stats without duplicates
 --snps               calls snps on the given bam
 --all                run all of the actions (does not include --rg)

 --rg                 run rg fix on bam
 
 Parameters
 -p, --project        project name of the samples
 -s, --sub_dir        sub direcotry in the project, usually lib name
 -o, --outname        name of the files created (or SE run name)
 -b, --bams           list of bams
 -d, --outdir         path of the base directory -- base_dir/project/..
 -c, --c_design       capture_design
 -q, --queue          cluster queue. default: normal
     --hg18           using human ref 18 (defaults with hg19) 
     --rg_id          rg id of the group (0,1,2..) defaults at 0.
     --sample         name of the sample


Example:
 Post processing all of the steps - merge, mark dups, cap_stat cap_nodupstat, snp calls
 $ ruby mu_driver.rb --all -p test -s ab1 -o ab1 -b "bam1 bam2 ..." -c c_design

 Post processing of the single steps 
 $ ruby mu_driver.rb --[merge|dups|cap_dup|cap_nodup|snps|all] -p test -s ab1 -b "bam|bams" [-c c_design]
 $ ruby mu_driver.rb --merge --cap_dup -p test -s ab1 -n ab1 -b "bam1 bam2 ..." -c c_design


 Specifically for rg fixes only
 $ ruby mu_driver.rb --rg -d outdir -p proj_name -s lib_name -o run_name [--rg_id num] 
                     --sample sample_name -b "bam file" 
