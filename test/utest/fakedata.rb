require 'net/ssh'
require 'fileutils'

class Fakedata
  def initialize
    @ip = "128.249.153.207"
  end

  def fakerawdata(name = "F3", type = "s", barcode = "")
    bc = ""
    if barcode !=""
      bc = "_#{barcode}"
    end

    File.open("0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2#{type}A_0100999999" +
              "9_1_#{name}#{bc}.csfasta", "w") do |f|
      f.puts("# Title: 0533_20100666_2_SLAWG_TOVA_61_1916_11A_N_2#{type}A_010" +
             "09999999_1")
      f.puts(">1279_37_175_#{name}")
      f.puts("T30101102100111221310213110011122011313110221101221")
      f.puts(">1279_37_325_#{name}")
      f.puts("T12102021300220212110221202112223001101320311232321")
      f.puts(">1279_37_444_#{name}")
      f.puts("T01312020000202232120112201012211232210013322020201")
    end

    File.open("0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2#{type}A_0100999999" +
              "9_1_#{name}_QV#{bc}.qual", "w") do |f|
      f.puts("# Title: 0533_20100666_2_SLAWG_TOVA_61_1916_11A_N_2#{type}A_010" +
             "09999999_1")
      f.puts(">1279_37_175_#{name}")
      f.puts("33 30 26 29 27 30 29 29 4 25 25 33 29 11 31 32 32 29 7 28 33 " +
             "31 33 15 33 27 19 30 26 29 30 28 5 32 32 26 6 28 19 33 19 27 " +
             "21 12 32 29 20 29 4 8")
      f.puts(">1279_37_325_#{name}")
      f.puts("27 16 29 25 29 16 25 14 15 28 30 31 28 25 32 20 27 14 25 15 " +
             "23 29 4 23 20 18 10 14 27 21 19 29 9 26 27 20 6 20 23 27 18 29" +
             " 22 24 29 11 19 20 28 19")
      f.puts(">1279_37_444_#{name}")
      f.puts("33 31 31 33 32 29 29 16 7 5 4 28 24 6 21 5 32 22 12 19 16 14 31" +
             " 7 22 18 13 19 12 16 24 26 30 7 19 4 26 25 7 27 15 29 23 4 11 8" +
             " 9 32 7 8")
    end
  end
  
  def ssh_fr(count = 1)
    ssh_fakerawdata
    if count != 1
      ssh_fakerawdata("F3", 20100612145459999)
    end
  end
  
  def ssh_mp(count = 1)
    ssh_fakerawdata("F3", 20100612145459025, "p")
    ssh_fakerawdata("R3", 20100612145459999, "p")
    if count !=1
      ssh_fakerawdata("F3", 20100612145451111,"p")
      ssh_fakerawdata("R3", 20100612145450000,"p")
    end
  end

  def ssh_pe(count = 1)
    ssh_fakerawdata
    ssh_fakerawdata("F5-P2", 20100612145459999)
    if count !=1
      ssh_fakerawdata("F3", 20100612145451111)
      ssh_fakerawdata("F5-P2", 20100612145450000)
    end
  end

  def ssh_bc(count = 1)
    ssh_fakerawdata("F3", 20100612145459025, "s", "BC1")
    ssh_fakerawdata("F3", 20100612145459999, "s", "BC2")
    ssh_fakerawdata("F3", 20100612145459111, "s", "BC3")
    ssh_fakerawdata("F3", 20100612145450000, "s", "BC4")
  
    if count !=1
      ssh_fakerawdata("F3", 20100612145455555, "s", "BC1")
      ssh_fakerawdata("F3", 20100612145456666, "s", "BC2")
      ssh_fakerawdata("F3", 20100612145457777, "s", "BC3")
      ssh_fakerawdata("F3", 20100612145453333, "s", "BC4")
    end
  end
  
  def ssh_fakerawdata(name = "F3", pr = 20100612145459025, type = "s", barcode = "")
    if barcode == ""
      lib = "defaultLibrary"
    else
      lib = barcode
    end
    primary = "primary.#{pr}"
    if name == "R3"
      primary = "primary.#{pr - 56000}"
    end

    dir = "/data/results/solid0533/0533_20100666_2_SL" +
          "/AWG_TOVA_61_1916_11A_N_2#{type}A_01009999999_1/results.F" +
          "1B1/libraries/#{lib}/#{primary}/reads"
    Net::SSH.start(@ip, "pipeline") do |ssh|
      ssh.exec! "mkdir -p #{dir}"
    end
    bc = ""
    if barcode !=""
      bc = "_#{barcode}"
    end
    fakerawdata(name, type, barcode)
    csfasta = "0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2#{type}A_0100999999" +
              "9_1_#{name}#{bc}.csfasta"
    qual    = "0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2#{type}A_0100999999" +
              "9_1_#{name}_QV#{bc}.qual"
    `rsync -avz #{csfasta} pipeline@#{@ip}:#{dir}`
    `rsync -avz #{qual} pipeline@#{@ip}:#{dir}`
    rm_fakerawdata(name,type, barcode)
  end  

  def ssh_create_done_flag
    dir = "/data/results/solid0533/0533_20100666_2_SL"
    Net::SSH.start(@ip, "pipeline") do |ssh|
      ssh.exec! "touch #{dir}/.slide_done.txt"
    end
  end

  def rm_ssh_fakerawdata
    Net::SSH.start(@ip, "pipeline") do |ssh|
      ssh.exec! "rm -rf /data/results/solid0533/0533_20100666_2_SL"
    end
  end

  def rm_fakerawdata(name = "F3",type = "s", barcode = "")
    bc = ""
    if barcode !=""
      bc = "_#{barcode}"
    end
    File.delete("0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2#{type}A_01009999" +
                "999_1_#{name}#{bc}.csfasta")
    File.delete("0533_20100666_2_SL_AWG_TOVA_61_1916_11A_N_2#{type}A_01009999" +
                "999_1_#{name}_QV#{bc}.qual")
  end

  def rm_new_slide_file
    file = "#{ENV['HOME']}/.hgsc_solid/solid0533/solid0533_new_slides.txt"
    if File.exist?(file)
      File.delete(file)
    end
  end

  def rm_done_slide_file
    file = "#{ENV['HOME']}/.hgsc_solid/solid0533/solid0533_done_slides.txt"
    if File.exist?(file)
      File.delete(file)
    end
  end

  def rm_tracking_dir
    dir = "#{ENV['HOME']}/.hgsc_solid"
    if File.directory?(dir)
      FileUtils.rm_rf(dir)
   end
  end  

  def rm_ardmore_files
    rm_done_slide_file
    dir = "/stornext/snfs5/next-gen/solid/results/solid0533/2010/06/0533_20100666_2_SL"
    FileUtils.rm_rf(dir)
  end
end

