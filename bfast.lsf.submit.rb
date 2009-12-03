#!/usr/bin/env ruby19

$:.unshift File.join(File.dirname(__FILE__))
%w(bfast.libs).each { |dep| require dep }

# Load config
ui = UInterface.instance
config = Config.new( YAML::load(ui.load_config(ARGV, $0)) )

# Get list of read splits/files
splits = Dir[config.global_reads_dir + "/*.fastq"]
# Prepare LSF 
lsf    = LSFDealer.new(config.input_run_name, 
                       config.global_lsf_queue,
                       splits.size)
# Prepare bfast cmd generation
cmds   = BfastCmd.new(config, splits)

# Per each split, create the basic bfast workflow with deps
one_machine = "rusage[mem=28000]span[hosts=1]"
reg_job     = "rusage[mem=4000]"
final_deps = []
splits.each do |s|
	sn  = s.split(".")[-2]
	dep = lsf.add_job("match" , cmds.match(s), sn, one_machine)
	dep = lsf.add_job("local" , cmds.local   , sn, one_machine, [dep])
	dep = lsf.add_job("postp" , cmds.post    , sn, reg_job    , [dep])
	dep = lsf.add_job("tobam" , cmds.tobam   , sn, reg_job    , [dep])
	dep = lsf.add_job("sort"  , cmds.sort    , sn, reg_job    , [dep])
	dep = lsf.add_job("index1", cmds.index1  , sn, reg_job    , [dep])
	#dep = lsf.add_job("index2", cmds.index2  , sn, reg_job    , [dep])
	lsf.blank "----------------"

	final_deps << dep
end

# when all the previous jobs are completed, we can merge all the bams
lsf.add_job("final_merge", cmds.final_merge, ".", reg_job, final_deps)

lsf.create_file

__END__
input_options:
 run_name: run_small_test
 f3: reads_f3
 r3: reads_r3
 qf3: quals_f3
 qr3: quals_r3
global_options:
 lsf_queue: test
 bfast_bin: /stornext/snfs1/next-gen/drio-scratch/bfast_related/bfast/bfast
 samtools_bin: /stornext/snfs1/next-gen/software/samtools-0.1.6
 space: CS
 fasta_file_name: /stornext/snfs3/drio_scratch/bf.indexes/small/test.fasta
 timing: ON
 logs_dir: /stornext/snfs3/drio_scratch/small_test/logs
 run_dir: /stornext/snfs3/drio_scratch/small_test/input
 reads_dir: /stornext/snfs3/drio_scratch/small_test/reads
 output_dir: /stornext/snfs3/drio_scratch/small_test/output
 tmp_dir: /space1/tmp/
 reads_per_file: 100000
match_options:
 threads: 8
local_options:
 threads: 8
post_options:
 algorithm: 4
