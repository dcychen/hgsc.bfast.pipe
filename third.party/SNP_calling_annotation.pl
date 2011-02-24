#! /usr/bin/perl -w
use File::Basename;

my $infile = $ARGV[0];
my $dirname = $ARGV[1];
my $sample_infile = basename($infile);
chdir "$dirname";

my $sample="";
if($sample_infile =~/^(.*?)\.bam$/)
{
	
	$sample = $1;
}
else
{
	print STDERR "Need a BAM input\n";
	exit(0);
}

print STDERR "\n.............................................................................\n";
print STDERR "For sample $sample\n\n";

$cmd = "/users/bainbrid/bin/java -cp /stornext/snfs0/next-gen/yw14-scratch/picard-tools/current/sam-1.18.jar:/stornext/snfs0/next-gen/yw14-scratch/picard-tools/current/picard-1.18.jar:/stornext/snfs0/next-gen/yw14-scratch/MNBLIB -Xmx4000M FilterBAMForSNPCalling $infile ".$sample.".sorted.dups.removed.bam";
print STDERR "$cmd\n\n";
system("$cmd");

$cmd = "/stornext/snfs0/next-gen/yw14-scratch/samtools-0.1.7a/samtools index ".$sample.".sorted.dups.removed.bam";

print STDERR "$cmd\n\n";
system("$cmd");

$cmd = "/stornext/snfs0/next-gen/yw14-scratch/samtools-0.1.7a/samtools pileup -vcf /stornext/snfs0/next-gen/yw14-scratch/hsap_36.1_hg18.fa ".$sample.".sorted.dups.removed.bam  >& ".$sample.".sorted.dups.removed.raw.pileup";
#$cmd = "/stornext/snfs0/next-gen/yw14-scratch/samtools-0.1.7a/samtools pileup -cf /stornext/snfs0/next-gen/yw14-scratch/hsap_36.1_hg18.fa ".$sample.".sorted.dups.removed.bam  >& ".$sample.".sorted.dups.removed.raw.wowv.pileup";

print STDERR "$cmd\n\n";
system("$cmd");

$cmd = "rm -f ".$sample.".sorted.dups.removed.bam";
#print STDERR "$cmd\n\n";
system("$cmd");

$cmd = "/users/bainbrid/bin/java -cp /stornext/snfs0/next-gen/yw14-scratch/picard-tools/current/sam-1.18.jar:/stornext/snfs0/next-gen/yw14-scratch/picard-tools/current/picard-1.18.jar:/stornext/snfs0/next-gen/yw14-scratch/MNBLIB -Xmx2000M FilterPileUpUniversal ".$sample.".sorted.dups.removed.raw.pileup > ".$sample.".GV"; 

print STDERR "$cmd\n\n";
system("$cmd");

$SNP_file = $sample.".SNPs";
$GV_file = $sample.".GV";
$INDEL_file = $sample.".INDELs";

open(FIN,"$GV_file");
open(FOUT_SNPS,"> $SNP_file");
open(FOUT_INDELS,"> $INDEL_file");
while(<FIN>)
{
	chomp;
	my @a=split(/\t/);
	if($a[2] ne "*")
	{
		print FOUT_SNPS "$_\n";
	}
	else
	{
		print FOUT_INDELS "$_\n";
	}
}
close(FIN);
close(FOUT_SNPS);
close(FOUT_INDELS); 

$cmd = "/stornext/snfs0/next-gen/project_SNP_calling/software/annotate_Ardmore.pl -c 0,1,2,2,3 -d 130 -i $SNP_file";
print STDERR "$cmd\n\n";
system("$cmd");

$cmd = "/stornext/snfs0/next-gen/yw14-scratch/miRNAnnotate/miRNAnnotate/miRNAnnotate.pl -c 0,1,2,2,3 -i $SNP_file";
print STDERR "$cmd\n\n";
system("$cmd");
