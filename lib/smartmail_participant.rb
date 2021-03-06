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

require 'yaml'
require 'kconv'
require 'rufus/scheduler'
require 'openwfe/util/xml'
require 'openwfe/util/json'
require 'smartmail_mailer'
require 'smartmail_gcal'
require 'smartmail_composer'
require 'smartmail_settings'

module OpenWFE
  module Extras

    class SmartmailParticipant
      include LocalParticipant

      def initialize( options = {} )
        @current_workitem = nil
        @wi_send_to = Hash.new
        @underline = [0x1B].pack("c*") + "[1;4;35m"
        @normal = [0x1B].pack("c*") + "[0m\n"
        @user_name, @send_to = Kconv.toutf8(options[:name]), options[:email]
        color_puts("added new participant #{@user_name}, #{@send_to}")
        @settings = SMSetting.load
        @reminder_header, @reminder_contents = 
          Kconv.toutf8(@settings["smartmail"]["reminder"]["header"]), 
          Kconv.toutf8(@settings["smartmail"]["reminder"]["contents"])
      end

      def consume( workitem )
        ldebug { "consuming workitem" }
        @current_workitem = workitem
        begin
          relation = UserProcessRelation.find_by_wfid( workitem.fei.wfid )
          user = User.find_by_id( (relation)? relation.user_id : -1 )
          puts "user_process_relation: #{workitem.fei.wfid} => #{user.id}.#{user.email}, #{@send_to}\n"
          if user && user.email
            @wi_send_to[ workitem.fei.wfid ] = user.email if @send_to == '_owner'
            workitem.fields['applicant'] = user.name
          else
            puts "Can not get owner's email address: #{user.inspect}"
          end
          step = workitem.params['step'] || 'unknown_step'
          color_puts "#{step} consuming workitem:"
          puts "consume: #{workitem}\n"
          email_workitem( workitem )
          wait_reply = (workitem.params['wait_for_reply'] == true)
          MailItem.get_workitem( workitem.fei, 'delete', "consume" ) unless wait_reply
          reply_to_engine( workitem ) unless wait_reply
        rescue Exception => e
          color_puts e.message
          puts e.backtrace
        end
      end

      def cancel (cancelitem)
        ArWorkitem.destroy_all([ 'fei = ?', cancelitem.fei.to_s ])
        relation = UserProcessRelation.find_by_wfid( cancelitem.fei.wfid )
        relation.destroy if relation
      end

      protected

      def color_puts( message )
        puts "#{@underline}#{message}#{@normal}"
      end

      def email_workitem( workitem )
        step = workitem.params["step"].gsub(/\"/,'') if workitem.params["step"]
        workitem.fields['user_name'] = @user_name
        color_puts "email_workitem: participant[#{step}:#{workitem.fields['worker']}]"
        send_to = @wi_send_to[ workitem.fei.wfid ] || @send_to
        send_to = fix_email_address( workitem, send_to ) unless is_email_address(send_to)
        format = decide_email_format(send_to)
        store_related_information( workitem )
        contents = SMComposer.compose( workitem, format )
        return unless contents
        # TODO: do not store workitem 2 times
        fei_store = MailItem.store_workitem( workitem, 'replace workitem' )
        puts "\n#{workitem.fields['fei_store_id']} === #{fei_store.id}"
        desc = workitem.fields['__sm_description__']
        mailer = SMailer.new
        mailer.set_reply_with_wfid( fei_store.id )
        mailer.set_to(send_to)
        puts "detected attach: #{workitem["attachment"]}" if workitem["attachment"]
        mailer.set_subject(contents[:title]).set_body(contents[:body], format)
        mailer.set_attach( workitem["attachment"] ) if workitem["attachment"]
        # p "process workitem: #{workitem}"
        scheduler = Rufus::Scheduler.start_new
        def scheduler.handle_exception (job, exception)
          puts "job #{job.job_id} caught exception '#{exception}'"
          # puts exception.backtrace
        end
        s_reminder = workitem.fields['__sm_reminder__'] || nil
        s_timeout = workitem.fields['__sm_timeout__'] || nil
        event = Hash.new
        event[:title] = "#{desc} #{contents[:title]} #{@user_name}"
        event[:desc] = "#{contents[:body][:plain]}"
        event[:end] = Time.now + Rufus::parse_time_string(s_timeout) if s_timeout
        user_calendar = (@user_name == 'フロー管理者')? 'default' : @user_name
        error = SMGoogleCalendar.create_event( event, user_calendar )
        puts error if error
        # block no reply steps to send reminder emails
        wait_reply = workitem.params['wait_for_reply']
        puts "reminder at #{s_reminder}, #{s_timeout}, wait_reply:#{wait_reply}"
        if s_reminder && s_timeout && wait_reply
          workitem.fields['__sm_reminder__'] = nil
          workitem.fields['__sm_timeout__'] = nil
          fei_id = fei_store.id.to_s
          first_time = true
          scheduler.every s_reminder, :timeout => s_timeout, :first_at => Time.now do |job|
            begin
              is_next_step = MailItem.get_workitem( fei_id ) == nil
              if is_next_step
                job.unschedule 
                raise "#{@user_name} escape from reminder loop."
              end
              unless first_time
                mailer.set_subject("#{@reminder_header}" + contents[:title])
                # mailer.set_body(contents[:body], format)
              end
              puts "#{@user_name} reminder: #{s_reminder}, #{s_timeout}, id:#{fei_id}?[#{is_next_step}]"
              mailer.send_email
              first_time = false
            rescue Rufus::Scheduler::TimeOutError => toe
            end
          end
        else
          mailer.send_email
        end
      end

      def store_related_information( workitem )
        flow_name = workitem.fei.wfname
        description = SMSpreadsheet.get_flow_description_from_spreadsheet( flow_name )
        workitem.fields['__sm_description__'] = description
        fei_store = MailItem.store_workitem( workitem )
        workitem.fields['fei_store_id'] = fei_store.id
        workitem.fields['step'] = workitem.params["step"].gsub(/\"/,'')
      end

      def fix_email_address( workitem, send_to )
        email = workitem[send_to]
        unless email
          workitem.attributes.each do |attr| 
            next unless attr.is_a? Hash
            attr.values.each do |_hash|
              next unless _hash.is_a? Hash
              email = _hash[send_to]
              break if email && email.size > 0
            end
          end
        end
        puts "fix_email_address: #{send_to} --> #{email}"
        puts " -- fix_email_address --> #{workitem}"
        email
      end

      def is_email_address( email_str )
        email_pattern = 
          /^[\x01-\x7F]+@(([-a-zA-Z0-9]+\.)*[a-zA-Z]+|\[\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\])/
          /#{email_pattern}/ =~ email_str
      end

      def decide_email_format( destination )
        # format = 'plain'
        format = 'html' # if /docomo|softbank|gmail/ =~ destination
        format
      end

    end
  end
end
