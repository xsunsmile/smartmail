require 'lib/smartmail_operation'
require 'lib/smartmail_formater'
require 'lib/smartmail_spreadsheet'

class SMComposer

  @@sheet_maps = nil

  def self.compose( workitem, format='plain' ) #format: plain or html
    # puts "compose email in format: #{format}"
    begin
      contents = translate_to_email_contents( workitem )
      email = SMFormater.format( contents, format )
      email
    rescue Exception => e
      puts $!
      puts e.backtrace
    end
  end

  protected

  def self.set_sheet_maps() 
    @@sheet_maps = Hash.new
    SMFormater.get_email_maps.each_pair do |mail_item,sheet_item|
      # puts "mail: #{mail_item}, #{sheet_item}"
      @@sheet_maps[mail_item] = Kconv.toutf8(sheet_item)
    end
    @@sheet_maps
  end

  def self.get_step_information( workitem )
    step_information = SMOperation.operate( workitem )
    return step_information if step_information
    process_name = workitem.fei.wfname
    step = workitem.params["step"].gsub(/\"/,'') if workitem.params["step"]
    step_information = SMOperation.get_step_information( process_name, step )
    information = Hash.new
    step_information.each {|it| information[it[:title]] = it[:contents]}
    return information
  end

  def self.wait_for_reply( info, workitem )
    field = Kconv.toutf8('返信を待つ')
    wait = info[field]
    puts "wait_for_reply: #{ wait == 'TRUE'}"
    workitem.params['wait_for_reply'] = ( wait == 'TRUE')
  end

  def self.translate_to_email_contents( workitem )
    step_information = get_step_information( workitem )
    #TODO: move wait_for_reply outside
    wait_for_reply( step_information, workitem )
    # step_information['SM_MAIL_HEADER'] = ''
    step_information
  end

end
