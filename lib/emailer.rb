#!/usr/bin/ruby
#
#

require 'net/smtp'

module Emailer
  #sends email
	def self.send_email(from, to, subject, message)

  	to_mail = ""
	  to.each { |x| to_mail= to_mail + ",#{x}" }

msg = <<END_OF_MESSAGE
From: <#{from}>
To: <#{to_mail}>
Subject: #{subject}

#{message}
END_OF_MESSAGE

  	Net::SMTP.start('smtp.bcm.tmc.edu') do |smtp|
	   smtp.send_message msg, from, to
	 end
	end

end
