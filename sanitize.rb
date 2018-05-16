#!/usr/local/bin/ruby
# coding: utf-8
#
# Copyright (C) 2017 New Media Tokushima Co.,Ltd. All rights reserved.

require 'mailparser'
require 'syslog'
include Syslog::Constants
require 'logger'

DUMMY_MAIL_TO = 'bcc@deco-project.org'

Syslog.open("DECO_MF", LOG_PID|LOG_NDELAY, LOG_MAIL) unless Syslog.opened?
Syslog.info("start")
Syslog.info("RCPT TO: [#{ARGV[0].chop}]")

mail = MailParser::Message.new($stdin.read)

Syslog.info("From: #{mail.from}")

# To: の数確認
flag_to = false
flag_to = true if mail.to.size > 1
Syslog.info("To size: #{mail.to.size}")

# Cc: の存在確認
flag_cc = false
flag_cc = true if mail.cc.size >= 1
Syslog.info("Cc size: #{mail.cc.size}")

# mail出力

# header
mail.header.add('x-mail-filter', "DECO Mail Filter\r\n")
mail.header.keys.each do | key |
  if key == 'to' && (flag_to || flag_cc)
    print "#{key}: #{DUMMY_MAIL_TO}\r\n"
    Syslog.info("fix To: #{DUMMY_MAIL_TO}")
  elsif key == 'cc'
    # drop
    Syslog.info("remove Cc")
  else
    if mail.header.raw(key).kind_of?(Array)
      mail.header.raw(key).each do | item |
        print "#{key}: #{item.to_s}"
      end
    else
      print "#{key}: #{mail.header.raw(key).to_s}"
    end
  end
end
# body
print mail.rawbody
Syslog.info("end")
