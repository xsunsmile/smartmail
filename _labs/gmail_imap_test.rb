
require '../lib/jmail'
require 'pp'

mailer = JMail.new( :config => '../config/config.yml' )
pp mailer.scan_imap_folder
# mails = imap.fetch(['FROM', 'hogehoge@example.com', 'UNSEEN'])
