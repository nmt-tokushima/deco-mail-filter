#!/usr/local/bin/ruby
# coding: utf-8
#
# Copyright (C) 2017 New Media Tokushima Co.,Ltd. All rights reserved.

require 'syslog'
include Syslog::Constants
require 'logger'

Syslog.open("DECO_MF", LOG_PID|LOG_NDELAY, LOG_MAIL) unless Syslog.opened?
Syslog.info("start")
Syslog.info("RCPT TO: [#{ARGV[0].chop}]")

require_relative 'src/core'

config = DecoMailFilter::Config.new(
  bcc_conversion: (ENV['DECO_MF_BCC_CONVERSION'] != '0'),
  encrypt_attachments: (ENV['DECO_MF_ENCRYPT_ATTACHMENTS'] != '0')
)
filter = DecoMailFilter::Core.new config: config
filter.logger = Syslog
print filter.work $stdin.read
