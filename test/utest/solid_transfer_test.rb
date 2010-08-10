#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#

$:.unshift File.join(File.dirname(__FILE__))
require 'fakedata'

main_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
require main_dir + "/lib/solid_transfer.rb"

a = Fakedata.new()
a.rm_ssh_fakerawdata
#a.ssh_fr(2)
a.ssh_mp(2)
#a.ssh_pe
#a.ssh_bc
a.ssh_create_done_flag
a.rm_ardmore_files

st = Solid_transfer.new("128.249.153.207", "dc12@bcm.edu".split)
st.transfer(5,"0533_20100666_2_SL")
st.completed_se(5, "0533_20100666_2_SL")

