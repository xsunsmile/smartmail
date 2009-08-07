
require '../lib/jmail'
require 'rubygems'
require 'uri'
require 'kconv'

mailer = JMail.new({ :config => '../config/config.yml' })

to = 'milog@docomo.ne.jp'
subject = '日本語タイトル'
reply_sub = '日本語返信タイトル'
reply_body = '日本語返信...本文'
reply_body2 = '日本語返信.##.本文'

options = Hash.new
conts = Hash.new
conts[:title] = reply_sub
conts[:contents] = reply_body
conts[:description] = 'GMAIL返信'
conts[:mailto] = 'smart.mailflow@gmail.com' # 'EZWEB返信' => 'milog@ezweb.ne.jp' }
options[0] = conts

text = '日本語返信...本文'
mailer.set_to(to).set_subject(subject).set_body(text,true,options).send
