#!/bin/bash
#
# Cleans a SEA directory from temporary data
#
# Author: David Rio Deiros

set -e

error()
{
  echo "Are you sure this is a SEA dir?"
  echo "ERROR: $1"
  exit 1
}

[ ! -f ./cluster_JOBS.sh ] && error "Can't find cluster_JOBS.sh file"
[ ! -f ./go.sh ] && error "Can't find go.sh file"
[ ! -d ./reads ] && error "Can't find reads dir"
[ ! -d ./output ] && error "Can't find output dir"

echo "rm -f ./cluster_JOBS.sh ./go.sh ./metric* ./email_info.txt"
rm -f ./cluster_JOBS.sh ./go.sh ./metric* 

if [ $1 == "rm_dups" ]
then
  echo "rm -f ./output/*merged.bam ./output/*sorted.bam ./output/*dups.bam" 
  rm -f ./output/*merged.bam ./output/*sorted.bam ./output/*dups.bam
else 
  echo "rm -f ./output/*merged.bam ./output/*sorted.bam"
  rm -f ./output/*merged.bam ./output/*sorted.bam
fi

echo "rm -rf reads ./output/split*"
rm -rf reads ./output/split*
echo "rm -f ./moab_logs/*job2log*"
rm -f ./moab_logs/*job2log  ./moab_logs/*/*job2log*
echo "rm -f split_jobs"
rm -rf split_jobs
