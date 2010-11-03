#!/usr/bin/env ruby
#
# Author: Phillip Coleman

=begin

== SYNOPSIS
 Attempts to connect to the passed in IP through ssh. It returns a boolean
 based off its success. 

 require 'ping'
 result = 'Ping.ping hostname

== Return Value

 boolean

=end

class Ping

  def Ping.ping(host)
    begin
      Net::SSH.start(host, "pipeline") do |ssh|
        name = ssh.exec! "hostname -s"
      end
      ret = true
    rescue
      ret = false
    end
  end
end
