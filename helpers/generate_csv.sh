#!/bin/bash
#
# Runs the ruby tool to generate csv output of our 
# SOLiD data. It checks the exit code and sends and
# email
#
help()
{
	echo "$1"
  cat <<EOF
Usage:
  $0 cmd output_path mail_to
Example:
  $0 "./bin/list_system_data.rb /stornext/snfs4/next-gen/solid/analysis" /tmp "deiros@bcm.edu dc12@bcm.edu"
EOF
	exit 1
}

send_email()
{
  error_ok=$1
  subject="csv dump tool heartbeat: {$error_ok}"

  if [ $error_ok == "OK" ] 
  then
    n_seas=$[$(cat $dump_to | wc -l) - 1]
  else
    n_seas="-"
  fi

  (
  cat <<EOF
Heart Beat for the CSV dumping of our SOLiD data
------------------------------------------------

Started : $started
Finished: $finished

# of seas processed: $n_seas

csv file: $dump_to
log file: $log_file
EOF
  ) | mail -s "$subject" $mail_to
}

# point the sym link to the latest csv
create_symlink()
{
  csv_symlink="$output/csv.dump.latest.csv"
  rm $csv_symlink
  ln -s $dump_to $csv_symlink
}

######################################################
# Main
######################################################
[ ".$1" == "." ] && help "Error param: cmd"
[ ".$2" == "." ] && help "Error param: output path"
[ ".$3" == "." ] && help "Error param: mail_to"

cmd="$1"
output="$2"
mail_to="$3"


#create the output path
year=`date +%Y`
month=`date +%m`
day=`date +%d`
output_path="$output/$year/$month/$day"
mkdir -p $output_path

# names of the output files
time_stamp=`date +%F.%T`
dump_to="$output_path/csv.dump.$time_stamp.csv"
log_file="$output_path/csv.dump.$time_stamp.log"

started=`date`
$cmd > $dump_to 2> $log_file &
wait
exit_code=$?

finished=`date`

if [ $exit_code -eq 0 ]
then
  send_email "OK"
  create_symlink
	exit 0
else
  send_email "ERROR"
	exit 1
fi
