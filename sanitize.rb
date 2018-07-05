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
filter = DecoMailFilter::Core.new config: config
filter.logger = Syslog
print filter.work $stdin.read
if filter.work_side_effect
  if filter.work_side_effect[:attachments_encryption]
    # TODO: パスワード連絡メール送信
    # filter.work_side_effect.password
    # NOTE: パスワードメール送信のタイミングをずらしたい場合は filter.work の結果を即座に print しないようにする
  end
end
