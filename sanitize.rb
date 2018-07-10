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

url = ENV['DECO_MF_CONFIG_URL']
url = (url.nil? || url == '') ? 'http://127.0.0.1/api/v1/setting.json' : url
config = DecoMailFilter::Config.create_from_json_url url
smtp_host = ENV['DECO_MF_SMTP_HOST']
smtp_host = (smtp_host.nil? || smtp_host == '') ? '127.0.0.1' : smtp_host
config.smtp_host = smtp_host
smtp_port = ENV['DECO_MF_SMTP_PORT']
smtp_port = (smtp_port.nil? || smtp_port == '') ? '25' : smtp_port
config.smtp_port = smtp_port
config.rcpts = ARGV[0].chop.split(/,/)

filter = DecoMailFilter::Core.new config: config
filter.logger = Syslog

begin
  output = filter.work $stdin.read
rescue UnsupportedEncodingMechanism => e
  exit 1 # TODO: ここで異常終了するとsmtpprox_for_decomfは正しく動ける？調べる
end
filter.work_before_output
print output
