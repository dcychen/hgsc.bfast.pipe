#!/usr/bin/env ruby
#
# This class will handle the transferring process of the raw data from 
# instrument to ardmore
#
# constructors: ip address of a machine, email is optional
# methods:
#   transfer(snfs, rname = "all") 
#     - transfers the data from instrument to ardmore. it will check if the SE 
#       is new, it will be stored in @new_slides. If email is provided, it 
#       will sent out an email for the new slide.
#     - snfs is to specify the destniation volume.
#     - if rname is not entered, this method will transfer all se on instrument.
#   completed_se(snfs, rname = "all")
#     - checks if the files have transferred completely. 
#       once the .slide_done.txt is detected, md5sum will be used 
#       to compare the files on instrument and the files transferred on ardmore.
#       when all of the files belonging to a SE checks out, it will store the 
#       se name to @done_slides  
#     - snfs is to specify the destniation volume.
#     - rname is the name of the SE (partial string is ok), if specified, it 
#       verify the transfer for the particular SE, otherwise it would do it for
#       all SE on the instrument.
#   check_ready_for_analysis?(se)
#     - checks if the SE raw data have been transferred and ready for analysis
#   stop_rsync
#     - kills the rsync processes that is from the given ip
#
# Author: David Chen

$:.unshift File.join(File.dirname(__FILE__))
require 'se_inst'
require 'fileutils'
require 'emailer'
require 'net/ssh'
require 'sequence_event'
require 'backup'
require 'time_helpers'

class Solid_transfer
  EMAIL_FROM = "p-solid@bcm.edu"
  def initialize(ip, email_to, check_file = 1)
    if check_file == 1
      @ses = Se_inst.new(ip)
    else
      @ses = Se_inst.new(ip,1)
    end
    @ip = ip
    @email_to = email_to
    @machine = @ses.ssh_hostname
    @new_slides  = "#{ENV['HOME']}/.hgsc_solid/#{@machine}/" +
                   "#{@machine}_new_slides.txt"
    @done_slides = "#{ENV['HOME']}/.hgsc_solid/#{@machine}/" +
                   "#{@machine}_done_slides.txt"
    @backup_file = "#{ENV['HOME']}/.hgsc_solid/backup/" +
                   "solid_raw_backup.txt"
    @trans_slides = "#{ENV['HOME']}/.hgsc_solid/automation/" +
                    "transferred.txt"
    @NUM_DAY_LOCK = 1
  end
   
  def transfer(snfs, rname = "all", send_email=1)
    data = @ses.all_se
    if rname == "all"
      keys = data.keys
    else
      keys = @ses.matching_keys(rname)
    end
    if keys.empty?
        Helpers::log("The SE name/string provided does not exist or there " +
                     "no runs on #{@machine}. Skipping..")
    else 
      keys.each do |se|
        if check_transferred?(se, @done_slides)
          Helpers::log("#{se} has been transferred. skipping.")
        else
          if lock_remove_after_day(@NUM_DAY_LOCK, se)
            # if lock file is not present, create one
            if !check_lock(se)
              create_lock(se)
            end

            check_new?(se, @new_slides, send_email)
            data[se].each do |p|
              rsync(p, dest_path(snfs, p, se))
            end
            remove_lock(se)
          else
            Helpers::log("#{se} lock is present, not going to transfer.")
          end
        end
      end
    end
  end

  def lock_remove_after_day(day, se)
     lock_f = "#{ENV['HOME']}/.hgsc_solid/#{@machine}/#{se}.lock"
     if File.exist?(lock_f)
       lock_f_t = File.new(lock_f).mtime
       now = Time.now
       difference = now - lock_f_t
       if difference > (TimeHelpers::SECS_IN_DAY * day.to_i)
         return true
       else
         return false
       end
     else
       return true
     end
  end


  # verifying if the files transferred is completed and correct
  def completed_se(snfs, rname = "all", send_email=1)
    data = @ses.all_se
    done_list = @ses.completed_run
    if done_list.size == 0
      Helpers::log("There are no SE slide done flag set on #{@machine}.")
      return TRUE
    end
    compared_list = []
    if rname == "all"
      compared_list = done_list
    else
      done_list.each do |d|
        compared_list << d if /#{d}/.match(rname)
      end
    end  
    compared_list.each do |d|
      keys = @ses.matching_keys(d)
      if keys.empty?
        Helpers::log("#{d} has slide done flag, but no SE found..? exiting.",1)
      end
      keys.each do |k|
         if lock_remove_after_day(@NUM_DAY_LOCK, k)
          # if lock file is not present, create one
          if !check_lock(k)
            create_lock(k)
          end
          if !check_transferred?(k, @done_slides)
            run_path = run_name_path(snfs, k)
            md5_file = "#{run_path}/md5sum_check.txt"
            files_checked = 0
            fasta_valid = TRUE
            rawdata = TRUE
            d_path = ""
            data[k].each do |p|
              filename = File.basename(p)
              d_path = dest_path(snfs,p)
              file = dest_path(snfs,p) + "/#{filename}"
              md5 = grab_md5_from_file(md5_file, filename)
              if md5 == ""
                Helpers::log("#{filename} md5sum not found in #{md5_file}." +
                             " Running check and saving to file.")
                md5 = `md5sum #{file}`
                add_line_to_file("#{run_path}/md5sum_check.txt", md5)
              end
              Helpers::log("checking #{p} md5sum on instrument")
              inst = ssh_md5sum_file(p)
              if md5.split[0] == inst.split[0]
                files_checked = files_checked + 1
                # verify the csfasta when the md5 checks out
                if /csfasta/.match(file)
                  valid_csfasta = check_csfasta(file)
                  if valid_csfasta.size != 0
                    fasta_valid = FALSE
                    Helpers::log("csfasta not valid!")
                    if email?
                      msg = "#{file} did not pass the csfasta validator."
                      Emailer::send_email(EMAIL_FROM, @email_to,
                                          "CSFASTA not valid!", msg)
                    end
                  end
                end
              else
                # remove the md5 line from file
                rm_md5_from_file(md5_file, filename)
                Helpers::log("md5s did not match. removing file: #{file}")
                # remove the file from ardmore
                FileUtils.rm_rf file 
              end
              if !/csfasta/.match(p) && !/qual/.match(p)
                rawdata = FALSE
              end
            end
            if files_checked == data[k].size && fasta_valid
              if rawdata
                Helpers::log("#{k} has been transferred. Emailing and adding run " +
                             "name to slide completed file.")
                add_line_to_file(@done_slides, k)
                #send to backup
                Backup::backup_data(@backup_file, d_path)
                if email? && send_email != 0
                  msg = "#{@machine}: #{k} has been fully transferred."
                  Emailer::send_email(EMAIL_FROM, @email_to, msg, msg)
                end
              else
                data[k].each do |f|
                  Helpers::log("#{f} has been transferred.")
                end
              end
            else
              Helpers::log("#{d} did not finish transferring or csfasta not " +
                           "valid.  Not adding to the slide completed file.")
            end
          else
            Helpers::log("#{d} has been transferred. Skip checking.")
          end
          remove_lock(k)
        else
          Helpers::log("#{k} lock is present, not going to check.")
        end
      end
    end
  end

  # checks if the SE is ready for analysis
  def check_ready_for_analysis?(se)
    temp = Sequence_event.new(se)
    check_transferred?(temp.to_s, @done_slides)
  end
 
  # stops the rsync process from the instrument
  def stop_rsync
    ps = grep_rsync_process
    ps.each do |l|
      if /#{@machine}/.match(l)
        kill_process(parse_pid(l))
      end
    end
  end

  private
  # checks in file to see if rname exists  
  def check_transferred?(rname, done_slides)
    Helpers::log("Checking if #{rname} has been transferred")
    dir = File.dirname(done_slides)
    if File.directory?(dir) && File.exist?(done_slides)
      known = File.open(done_slides).readlines.map!{ |e| e.chomp }
      return known.include?(rname)
    end
    FileUtils.mkdir_p(dir)
    File.new(done_slides, "w")
    return FALSE
  end

  # append the input to the end of the file
  def add_line_to_file(file, line)
    File.open(file, "a") {|f| f.puts("#{line}")}
  end

  # returns the destination path in ardmore
  def dest_path(num, path, se_name = "empty")
    des = "/stornext/snfs#{num}/next-gen/solid/results"
    if !File.directory?(des)
      remove_lock(se_name)
      Helpers::log("snfs#{num} does not exist. exiting..", 1)
    end
    dirs = @ses.path_parse(path)
    se = Sequence_event.new(@ses.run_name_from_path(path))
    des = des + "/#{dirs.mach}/#{se.year}/#{se.month}" +
          "/#{dirs.rname}/#{dirs.sample}"
    if (/csfasta/.match(path) || /qual/.match(path)) && /BC/.match(path)
      return des + "/#{dirs.bc}"
    end
    des
  end

  # returns run path in ardmore given the snfs# and run name
  def run_name_path(num, run)
    se = Sequence_event.new(run)
    des = "/stornext/snfs#{num}/next-gen/solid/results"
    if !File.directory?(des)
      Helpers::log("snfs#{num} does not exist. exiting..", 1)
    end

    des + "/" + @machine + "/" + se.year + "/" + se.month +
    "/" + se.rname
  end

  # checks the md5sum of the file on ardmore
  def md5sum_file(file)
    return `md5sum #{file}`
  end

  # checks the md5sum of the file on instrument
  def ssh_md5sum_file(file)
    df = ""
    Net::SSH.start(@ip, "pipeline") do |ssh|
      df = ssh.exec! "md5sum #{file}"
    end
    df
  end

  # return the length of the sequence
  def get_bp_length(fasta_path)
    return `tail -1 #{fasta_path} | wc | awk '{ print $NF}'`.to_i - 2
  end

  # checks if email is passed in or a nil
  def email?
    !@email_to.nil?
  end

  # checks the integrity of the csfasta
  def check_csfasta(fasta)
  # length is the total read lengh + 2
  # cat *.csfasta | perl -ne 'next if /^#/;$i++;if ($i%2==0) {print unless 
  # length($_)==52} else {print unless /^>\d+_\d+\_\d+\_(F|R)(3|5)(-P2)*\n$/}'
  # | more
    length = get_bp_length(fasta) + 2
    i = 0
    output = ""
    File.open(fasta).each do |l|
      next if /^#/.match(l)
      i = i + 1
      if ( i % 2 == 0 ) && ( l.size != length ) &&
        !/^>\\d+_\\d+_\\d+_(F|R)(3|5)(-P2)*\n$/.match(l)
        output = output + l
      end
    end
    output
  end

  # check if the SE is new
  def check_new?(rname, new_slides, send_email)
    Helpers::log("Checking to see if this is a new SE..")
    dir = File.dirname(new_slides)
    if !File.directory?(dir) || !File.exist?(new_slides)
      FileUtils.mkdir_p(dir)
      File.new(new_slides, "w")
    end
    known = File.open(new_slides).readlines.map!{ |e| e.chomp }
    if !known.include?(rname)
      Helpers::log("New SE: #{rname}")
      if email? && send_email != 0
        msg = "New SE on #{@machine}: #{rname}"
        Emailer::send_email(EMAIL_FROM, @email_to, msg, msg)
      end
      add_line_to_file(new_slides, rname)
      return TRUE
    end
    return FALSE
  end

  # returns the cfile md5 checksum
  def grab_md5_from_file(file_path, cfile)
    Helpers::log("Checking #{file_path} for #{cfile} md5sum")
    if File.exist?(file_path)
      md5 = ""
      File.open(file_path).each do |f|
        if /#{cfile}/.match(f)
          md5 = f
        end
      end
      md5
    else
      File.new(file_path,"w")
      ""
    end
  end

  # remove the cfile md5checksum line
  def rm_md5_from_file(file_path, cfile)
    Helpers::log("#{cfile} md5sum doesn't match instrument. Removing from " +
                 "#{file_path}.")
    File.rename(file_path, "#{file_path}.old")
    file = File.open(file_path,"w")
    File.open("#{file_path}.old").each do |f|
      next if /#{cfile}/.match(f)
      file.puts(f)
    end
    file.close
    File.delete("#{file_path}.old")
  end

  # rsyncs the file from instrument to ardmore
  def rsync(origin, final)
    if !File.directory? final
      FileUtils.mkdir_p(final)
    end
    Helpers::log("rsync -avz pipeline@#{@ip}:#{origin} #{final}")
    `rsync -avz pipeline@#{@ip}:#{origin} #{final}`
  end

  # creates the lock file
  def create_lock(run_name)
    Helpers::log("Locking #{run_name}")
    dir = "#{ENV['HOME']}/.hgsc_solid/#{@machine}"
    if !File.directory?(dir)
      FileUtils.mkdir_p(dir)
    end
    Lock::create_lock_file("#{dir}/#{run_name}.lock")
  end

  # check if the lock file is there
  def check_lock(run_name)
    Helpers::log("Checking lock file for #{run_name}")
    File.exists?("#{ENV['HOME']}/.hgsc_solid/#{@machine}/#{run_name}.lock")
  end

  # removes the lock file
  def remove_lock(run_name)
    Helpers::log("Removing lock for #{run_name}")
    Lock::remove_lock_file("#{ENV['HOME']}/.hgsc_solid/#{@machine}/#{run_name}.lock")
  end

  # parse out and returns the pid
  def parse_pid(pr)
    pr.split[1]
  end

  # kills the given pid on the instrument
  def kill_process(pid)
    Net::SSH.start(@ip, "pipeline") do |ssh|
      ssh.exec! "kill #{pid}"
    end
  end

  # finds all the rsync process on the instrument
  def grep_rsync_process
    ps = ""
    Net::SSH.start(@ip, "pipeline") do |ssh|
      ps = ssh.exec! "ps -ef | grep rsync"
    end
    ps.split("\n")
  end
end
