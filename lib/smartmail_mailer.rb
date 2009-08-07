require 'rubygems'
require 'uri'
require 'base64'
require 'tmail'
require 'tlsmail'
require 'net/smtp'
require 'net/imap'
require 'kconv'
require 'nkf'
require 'pp'
require 'lib/smartmail_settings'

class SMailer

  @@attachment_path = 'tmp/attachments/'

  attr_reader :to_address

  def initialize( params=Hash.new )
    @mail = TMail::Mail.new
    @mail.mime_version = '1.0'
    @settings = SMSetting.load( params[:config] )
    params = @settings["smartmail"]
    @helo_domain = params["domain_name"] || 'localhost.localdomain'
    @account = params["user_name"]
    @password = params["user_password"]
    @authtype = params["login"] || 'plain'
    smtp_server = params["smtp_server"] || 'localhost'
    smtp_server_port = params["smtp_server_port"] || '25'
    @smtp_server = Net::SMTP.new( smtp_server, smtp_server_port )
    @imap_server = Net::IMAP.new( params['imap_server'], params['imap_server_port'], true)
    @from_address = params["from_address"]
  end

  def set_account( params )
    @helo_domain = params["domain_name"] || 'localhost.localdomain'
    @account = params["user_name"]
    @password = params["user_password"]
    @authtype = params["login"] || 'plain'
    smtp_server_port = params["smtp_server_port"]
    @smtp_server = Net::SMTP.new( smtp_server, smtp_server_port )
    self
  end

  def set_to(to_address)
    # p "emailto: #{to_address}"
    return unless to_address
    @mail.to = to_address.split(/,/)
    @to_address = to_address.split(/,/)
    self
  end

  def set_reply_with_wfid( wfid )
    reply_to = @from_address.split(/@/)
    @mail.from = "#{reply_to[0]}+#{wfid}@#{reply_to[1]}"
    @mail.reply_to = @mail.from
    # p "from:#{@mail.from}, reply_to: #{@mail.reply_to}"
    self
  end

  def set_subject(subject)
    # p "subject: #{subject}"
    @mail.subject = Kconv.tojis(subject)
    self
  end

  def set_body( body, use_html=false )
    set_text_body( body )
    set_html_body( body ) if use_html == 'html'
    self
  end

  def set_html_body( body )
    @mail.set_content_type 'multipart','alternative'
    main_html = TMail::Mail.new
    main_html.set_content_type 'text', 'html', {'charset'=>'iso-2022-jp'}
    # main_html.body = URI.escape(Kconv.tojis(body[:html]))
    main_html.body = Kconv.tojis(body[:html])
    @mail.parts.push main_html
  end

  def set_text_body( body )
    main_text = TMail::Mail.new
    main_text.set_content_type 'text', 'plain', {'charset'=>'iso-2022-jp'}
    main_text.body = Kconv.tojis(body[:plain])
    @mail.parts.push main_text
  end

  def print
    pp @mail
  end

  def send()
    @mail.date = Time.now
    @mail.write_back
    p "do send email to:#{@to_address}"
    return unless @to_address
    @smtp_server.enable_tls(OpenSSL::SSL::VERIFY_NONE)
    @smtp_server.start( @helo_domain, @account, @password, @authtype ) do |smtp|
      smtp.sendmail(@mail.encoded, @mail.from, *@to_address)
    end
    # p "sent email: #{@to_address}"
  end

  def is_ascii(string)
    return string =~ /[^[:print:]]/
  end

  def set_attach(single_file_path)
    puts "set_attach: #{single_file_path}"
    return unless single_file_path.is_a? String
    attach = TMail::Mail.new
    file_path = Kconv.toutf8(single_file_path)
    file_path = "./"+file_path if !(/\// =~ file_path)
    %r|(^.*)/(.+$)|.match(file_path)
    file_path, file_name = $1, $2
    tmp_file_path = File.expand_path(file_name,file_path)
    attach.body = Base64.encode64(File.read(tmp_file_path))
    puts "set_attach: #{file_path}"
    file_name = Kconv.tojis(file_name).split(//,1).pack('m').chomp
    file_name = "=?ISO-2022-JP?B?"+file_name.gsub('\n', '')+"?="
    attach.set_content_type 'application','octet-stream','name' => file_name
    attach.set_content_disposition 'attachment','filename'=> file_name
    attach.transfer_encoding = 'base64'
    @mail.parts.push attach
    self
  end

  def send_to( mail_to, subject, message, attachment=nil )
    p "send email: #{mail_to} #{subject} #{message} #{attachment}"
    set_to( mail_to )
    set_subject( subject ) if subject
    set_body( message ) if message
    attachment.each { |att| set_attach( att ) } if attachment
    send
  end

  def analysis( email_content, to_utf8=false )
    details = Hash.new
    email = TMail::Mail.parse(email_content)
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
    # details[:from], details[:attachment] = email.from, attachments
    details[:to], details[:from], details[:attachment] = email['Delivered-To'].to_s, email.from, attachments
    details.each_pair { |k,v| print "analysis email: #{k} => #{v}\n" }
    details
  end

  def scan(eamil_storage_dir, pattern='*')
    email_contents = Array.new
    # p "scan_dir #{Dir::entries(eamil_storage_dir)} ..."
    Dir::glob("#{eamil_storage_dir}/#{pattern}").each { |email|
      email_contents << analysis(open(email).read)
      File::delete(email)
    }
    email_contents
  end

  def scan_imap_folder( folder_name="INBOX", filter=false )
    filter = ["NOT", "SEEN"] unless filter
    emails = Array.new
    begin
      puts "Login"
      @imap_server.login( @account, @password )
      @imap_server.select( folder_name )
      @imap_server.search( filter ).each do |message_id|
        email_contents_env = @imap_server.fetch(message_id, "RFC822")
        # puts "fetch email: #{message_id}"
        next unless email_contents_env
        email_contents = email_contents_env[0].attr["RFC822"]
        puts "analysis email: #{message_id}"
        email = analysis( email_contents )
        emails << email
        move_to_imap_folder( message_id, folder_name, get_workflow_folder( email ) )
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    ensure
      @imap_server.logout()
      # @imap_server.disconnect() 
    end
    emails
  end

  def add_response_handler
    @imap_server.add_response_handler { |resp|
      if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
        puts "Mailbox now has #{resp.data} messages"
      end
    }
  end

  def move_to_imap_folder( message_id, from_folder, to_folder )
    @imap_server.store( message_id, "+FLAGS", [:SEEN] )
    to_folder.each do |tag_name|
      next unless tag_name && tag_name.size > 0
      folder_name = Net::IMAP::encode_utf7( tag_name )
      puts "add #{tag_name} to email:#{message_id}"
      @imap_server.examine( folder_name ) rescue @imap_server.create( folder_name )
      @imap_server.select( from_folder )
      @imap_server.copy( message_id, folder_name )
    end
    @imap_server.store( message_id, "+FLAGS", [:DELETED] )
    @imap_server.expunge()
    puts "delete email:#{message_id}"
  end 

  def get_workflow_description( email )
    description = ''
    pattern = /(=+)\s(.+)\s(=+)/
    email[:body].split(/\n/).each do |line|
      next unless line
      line = Kconv.toutf8( line )
      description = $2.gsub(/=/,'') if /#{pattern}/ =~ line
        # p "test description: #{line} --> desc:#{description} BINGO! " if description.size > 0
        break if description.size > 0
    end
    description
  end

  def get_workflow_folder( email )
    smartmail_tag = @settings['smartmail']['deal_with_tag']
    folder_name = Array.new
    _ps_type, _store_id = $1, $2, $3 if /\+([a-z]+)?_?([\d]+)@/ =~ email[:to]
    workitem = MailItem.get_workitem( _store_id ) if _store_id
    if workitem
      desc = workitem.fields['__sm_description__']
      _ps_type = "#{workitem.fields['step']}" + (_ps_type)? "_#{_ps_type}" : ''
      _people = "#{workitem.fields['user_name']}<#{email[:from].join(',')}>"
    end
    _today = Time.now
    _time_tag = "#{smartmail_tag}#{_today.year}-#{_today.month}-#{_today.day}"
    folder_name = [desc, _ps_type, _time_tag, _people].compact
    folder_name.each {|tag| puts "use tag: #{tag}" }
    folder_name
  end

  def test
  end

end
