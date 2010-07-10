require 'kconv'
require 'lib/smartmail_participant'
require 'lib/smartmail_operation'
require 'lib/smartmail_spreadsheet'
require 'lib/smartmail_settings'

def add_worker_from_spreadsheet
  SMSpreadsheet.get_smartmail_participants_information.each do |item|
    worker = OpenWFE::Extras::SmartmailParticipant.new( :name => item[0], :email => item[1] )
    RuotePlugin.ruote_engine.register_participant( item[0], worker )
  end
end

if RuotePlugin.ruote_engine
  # only enter this block if the engine is running

  # This is a test participant
  #
  # Feel free to comment it out / erase it
  #

  @underline = [0x1B].pack("c*") + "[1;4;37m"
  @normal = [0x1B].pack("c*") + "[0m\n"

  add_worker_from_spreadsheet

  settings = SMSetting.load()
  params = settings["smartmail"]
  smartmail_address = params["from_address"]

  owner = OpenWFE::Extras::SmartmailParticipant.new( :name => 'フロー管理者', :email => '_owner' )
  RuotePlugin.ruote_engine.register_participant( "owner", owner )

  smartmail = OpenWFE::Extras::SmartmailParticipant.new( :name => 'smartmail', :email => smartmail_address )
  RuotePlugin.ruote_engine.register_participant( "smartmail", smartmail )

  RuotePlugin.ruote_engine.register_participant 'set_timeout' do |workitem|
    begin
      step, process_name = workitem.params['step'], workitem.fei.wfname
      step_info = SMOperation.get_step_information( process_name, step )
      s_timeout = nil
      step_info.each do |f|
        settings = f[:contents]
        s_timeout = $1 if /\{sm_reminder:[\d+\w+]*,([\d+\w+]*)\}/ =~ settings
        break if s_timeout && s_timeout.size > 0
      end
      return unless s_timeout
      puts "#{@underline}for flow:#{process_name} set_timeout:#{s_timeout} for step:#{step}#{@normal}"
      workitem.fields['timeout'] = s_timeout
    rescue Exception => e
      puts "set_timeout: #{e.message}"
    end
  end

  RuotePlugin.ruote_engine.register_participant 'poll' do |workitem|
    begin
      # args --> v:positiveAnswers,l:positiveMust,b:polling_break
      args, wfid = workitem.params['args'], workitem.fei.wfid
      poll_infos = Hash.new
      args.split(/,/).each do |field|
        poll_infos['polling_name'] = $1 if field =~ /^v:(.*)/
        poll_infos['polling_limit'] = $1 if field =~ /^l:(.*)/
        poll_infos['break_point'] = $1 if field =~ /^b:(.*)/
      end
      polling_value, polling_name, limit = 0, poll_infos['polling_name'], workitem.fields[poll_infos['polling_limit']]
      Poll.find_all_by_wfid( wfid ).each do |item|
        polling_value = polling_value + 1 if item.polling_name.to_s == polling_name.to_s
      end
      workitem.fields[ polling_name ] = polling_value if polling_value > 0
      puts "polling: #{polling_name}:#{polling_value} <=> #{limit}, #{poll_infos['break_point']}"
      if limit =~ /^\d+$/ && polling_value >= limit.to_i
        workitem.fields[ poll_infos['break_point'] ] = true
        puts "polling: #{poll_infos['break_point']} ==> true"
      end
    rescue Exception => e
      puts "polling error: #{e.message}"
      puts "polling error: #{e.inspect}"
    end
  end

  RuotePlugin.ruote_engine.register_participant 'print' do |workitem|

    begin
      email_contents = SMComposer.compose( workitem )
      # puts email_contents

      step = workitem.params['step']

      if step == 'send_job'
        worker = workitem.fields['worker']
        message1 = { 
          :body => "#{worker}質問です。\n\r\n", 
          :to => "mail+he_#{workitem.fei.wfid}@question.com" 
        }
        message2 = { 
          :body => "#{worker} 結果です。\n\r\n",
          :to => ""
        }
        result = (rand(100)%5==1)? message1 : message2
        puts "step:#{step} result:#{result}"
      end

      if step == 'help'
        worker = workitem.fields['worker']
        result = { 
          :body => "#{worker}答えです \n\r\n",
          :to => "mail+an_#{workitem.fei.wfid}@question.com"
        }
        puts "step:#{step} result:#{result}"
      end

      SMOperation.build( result, workitem )

    rescue Exception => e
      puts $!
      puts e.backtrace
    end

  end

  RuotePlugin.ruote_engine.register_participant 'buy_item' do |workitem|

    begin
      email_contents = SMComposer.compose( workitem )
      # puts email_contents

      step = workitem.params['step']

      if step == 'send_job'
        worker = workitem.fields['worker']
        message1 = { 
          :body => "#{worker}質問です。\n\r\n", 
          :to => "mail+he_#{workitem.fei.wfid}@question.com" 
        }
        message2 = { 
          :body => "#{worker} 結果です。\n\r\n",
          :to => ""
        }
        result = (rand(100)%5==1)? message1 : message2
        puts "step:#{step} result:#{result}"
      end

      if step == 'help'
        worker = workitem.fields['worker']
        result = { 
          :body => "#{worker}答えです \n\r\n",
          :to => "mail+an_#{workitem.fei.wfid}@question.com"
        }
        puts "step:#{step} result:#{result}"
      end

      SMOperation.build( result, workitem )

    rescue Exception => e
      puts $!
      puts e.backtrace
    end

  end

end
