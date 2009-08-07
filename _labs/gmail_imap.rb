
require 'rubygems'
require 'net/imap'
require 'kconv'
require 'tmail'

def analysis( mail_string, to_utf8=true )
    details = Hash.new
    email = TMail::Mail.parse(mail_string)
    subject = (to_utf8)? NKF.nkf("-w", email.subject):email.subject
    body = (to_utf8)? NKF.nkf("-w", email.body):email.body
    attachments = Array.new
    if email.has_attachments?
        for attachment in email.attachments
            filename = @@attachment_path + NKF.nkf("-w", attachment.original_filename)
            File.open(filename,'wb') { |f| f.write(attachment.read) }
            attachments << filename
        end
    end
    details[:subject], details[:body] = subject, body
    details[:to], details[:from], details[:attachment] = email.to, email.from, attachments
    # details.each_pair { |k,v| print "analysis email: #{k} => #{v}\n" }
    details
end

@config = Hash.new
@config['server'] = 'imap.gmail.com'
@config['port'] = '993'
@config['username'] = 'smart.mailflow@gmail.com'
@config['password'] = 'gks-smartmail'

imap = Net::IMAP.new(@config['server'],@config['port'],true)
imap.login(@config['username'], @config['password'])

# list = imap.list("", "*")
# mbox_name = Net::IMAP::decode_utf7(mbox.name)

imap.select('INBOX')
imap.search(["NOT", "DELETED"]).each do |message_id|
    email_contents = imap.fetch(message_id, "RFC822")[0].attr["RFC822"]
    email = analysis( email_contents )
    print email
    imap.store(message_id, "+FLAGS", [:SEEN])
    imap.copy(message_id, 'sunhao')
    imap.store(message_id, "+FLAGS", [:DELETED])
end
imap.logout()
imap.disconnect() 
