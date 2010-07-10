#--
# Copyright (c) 2008-2009, Kenneth Kalmer, opensourcery.co.za
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Africa. Kenneth Kalmer of opensourcery.co.za
#++

require 'thread'
require 'yaml'

require 'openwfe/util/xml'
require 'openwfe/util/json'
require 'openwfe/service'
require 'openwfe/listeners/listener'
require 'openwfe/extras/participants/ar_participants'

require 'smartmail_operation'
require 'smartmail_spreadsheet'
require 'smartmail_mailer'
require 'smartmail_settings'
require 'smartmail_gcal'

module OpenWFE
  module Extras

    #
    # Use Jabber (XMPP) during a workflow to communicate with people/processes
    # outside the running engine in an asynchrous fashion.
    #
    class SmartmailListener < Service
      include WorkItemListener
      include Rufus::Schedulable

      @@underline = [0x1B].pack("c*") + "[1;4;32m"
      @@normal = [0x1B].pack("c*") + "[0m\n"

      def initialize( service_name, options )
        @mutex = Mutex.new
        settings = SMSetting.load
        @store_name_prefix = settings["smartmail"]["store_name"]
        @blue_underline = [0x1B].pack("c*") + "[1;4;34m"
        @normal = [0x1B].pack("c*") + "[0m\n"
        service_name = "#{self.class}"
        puts "new smartmail listener"
        super( service_name, options )
      end

      def trigger( params )
        @mutex.synchronize do
          ldebug { "trigger()" }
          begin
            mailer = SMailer.new
            mailer.scan_imap_folder.each do |mail|
              puts "#{@@underline}listener dealing with email: #{mail[:from]}#{@@normal}"
              workitem = decode_workitem( mail )
              ldebug { "workitem: #{workitem.inspect}" }
              next unless workitem && !(workitem.is_a? String)
              print "#{@@underline}listener:send back workitem:#{@@normal} #{workitem}\n"
              decode_success = workitem["decode_success"]
              if decode_success
                handle_item(workitem)
              else
                send_error_email( mail, workitem )
              end
            end
          rescue Exception => e
            puts "#{@@underline}smartmail listener trigger error#{@@normal}"
            puts e.message
            puts e.backtrace
          end
        end
      end

      protected

      def send_error_email( mail, workitem )
        _mailer = SMailer.new
        _mailer.set_to(mail[:from])
        process_name_now = workitem["__sm_jobname__"]
        process_name_now = "ProcessError(#{workitem.fei.wfid})" unless process_name_now
        process_name_now.gsub!(/__sm_sep__/,'')
        subject_new = "#{process_name_now} " + mail[:subject]
        body = Hash.new
        body[:plain] = "Email decode error\n\n#{mail[:body]}"
        _mailer.set_subject(subject_new).set_body(body)
        _mailer.send_email
      end

      def get_arwi_id_for_decode( email )
        mail_to = email[:to]
        arwi_id = rescue_arwi_id_from_mailto( mail_to ) unless arwi_id.is_a? String
        unless arwi_id
          title = Kconv.toutf8( email[:subject] )
          arwi_id = $1 if title =~ /\((\d+)\)/
        end
        return arwi_id if arwi_id.is_a? String
      end

      # Complicated guesswork that needs to happen here to detect the format
      def decode_workitem( email )
        ldebug { "decoding workitem from: #{email}" }
        analysis_error_response( email )
        arwi_id = get_arwi_id_for_decode( email )
        puts "listener got arwi:#{arwi_id}"
        return unless arwi_id && arwi_id.to_s.size > 0
        workitem = (arwi_id.to_i == 0)? 
          create_new_process(email) : 
          MailItem.get_workitem(arwi_id, 'not_delete', "listener")
        puts "listener can not got workitem for arwi:#{arwi_id}" unless workitem
        return unless workitem
        puts "listener got wi:#{workitem.class}, #{workitem}"
        workitem["attachment"] = email[:attachment]
        workitem["email_from"] = email[:from].join(',')
        begin
          decode_infos = SMOperation.build( email, workitem )
          workitem["decode_success"] = decode_infos["decode_success"]
          email[:subject] = Kconv.toutf8(email[:subject])
          # _ps_type = $1 if /\+([a-z]+)?_?([\d]+)@/ =~ email[:to]
          # step = SMSpreadsheet.get_stepname_from_spreadsheet( workitem.fei.wfname, _ps_type )
          # event = Hash.new
          # event[:title] = "#{email[:subject]}"
          # event[:desc] = "#{email[:body]}"
          # calendar_name = workitem.fields['user_name'] || 'default'
          # SMGoogleCalendar.create_event( event, calendar_name )
        rescue Exception => e
          puts "decode_workitem error: #{e.message}"
          puts e.backtrace #.join("\n")
        end
        print "#{@blue_underline}3.listener processed workitem:#{@normal} #{workitem}\n"
        MailItem.get_workitem(arwi_id,'delete',"listener") if workitem["decode_success"]
        workitem
      end

      def create_new_process(email)
        params = Hash.new
        email_address = email[:from]
        # title = "業務依頼(Job Request)[スマートメールテスト]"
        title = email[:subject]
        process_type, process_name = $1,$2 if title =~ /\((.*)\)\[(.*)\]/
        _def = Definition.find_by_name( process_type )
        fields = (eval(_def.launch_fields.gsub(/:/,"=>")) rescue Hash.new)
        fields["__sm_jobname__"] = process_name
        params["attributes"] = fields
        params["workflow_definition_url"] = "/var/www/smartmail-dev/public/defs/#{_def.uri}"
        # params["last_modified"] = Date.new
        li = OpenWFE::LaunchItem.from_h(params)
        # puts li.inspect
        # RuotePlugin.ruote_engine
        _user = User.find_by_email( email_address )
        if _user
          options = { :variables => { 'launcher' => _user.login } }
          fei = RuotePlugin.ruote_engine.launch(li, options)
          # MailProcessRelation(id: integer, mail_body: string, fei: string
          process_store = MailProcessRelation.new
          mail_body = Kconv.toutf8(email[:body])
          process_store.mail_body = mail_body
          process_store.fei = fei.wfid
          process_store.save!
          puts "store emailcon: #{fei.wfid} --> #{mail_body}"
          unless UserProcessRelation.find_by_wfid( fei.wfid )
            relation = UserProcessRelation.new
            relation.user_id = _user.id
            relation.wfid = fei.wfid
            relation.save!
          end
          puts fei.inspect
        else
          send_error_email( email, fields )
        end
      end

      def analysis_error_response( email )
        message = email[:body]
        return unless message && message.size > 0
        message = message.gsub(/\n|\r|\r\n/,"__NEWLINE__")
        error_message_pattern = "Delivery to the following recipient failed permanently:"
        return unless /"#{error_message_pattern}"/ =~ error_message_pattern
        send_to_pattern = "Reply-To:(.*)\n"
        send_to = $1 if /"#{send_to_pattern}"/ =~ message
        item_id = $1 if /\+(\d+)@/ =~ message
        puts "analysis_error_response: #{send_to}"
        puts "analysis_error_response: #{item_id}"
      end

      def rescue_arwi_id_from_mailto( mail_to )
        arwi_id = nil
        p "test mail_to: #{mail_to}"
        if /\+([a-z]*)?_?(\d+)@/ =~ mail_to
          arwi_id = $2 
        end
        arwi_id
      end

    end
  end
end
