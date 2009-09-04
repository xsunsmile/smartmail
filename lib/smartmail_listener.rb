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
              handle_item( workitem )
            end
          rescue Exception => e
            puts "#{@@underline}smartmail listener trigger error#{@@normal}"
            puts e.message
            puts e.backtrace
          end
        end
      end

      protected

      def get_arwi_id_for_decode( email )
        mail_to = email[:to]
        arwi_id = rescue_arwi_id_from_mailto( mail_to ) unless arwi_id.is_a? String
        return arwi_id if arwi_id.is_a? String
      end

      # Complicated guesswork that needs to happen here to detect the format
      def decode_workitem( email )
        ldebug { "decoding workitem from: #{email}" }
        analysis_error_response( email )
        arwi_id = get_arwi_id_for_decode( email )
        puts "listener got arwi:#{arwi_id}"
        return unless arwi_id && arwi_id.to_s.size > 0
        workitem = MailItem.get_workitem( arwi_id, 'delete' )
        return unless workitem
        puts "listener got wi:#{workitem.class}, #{workitem}"
        workitem.fields["attachment"] = email[:attachment]
        begin
          SMOperation.build( email, workitem )
          event = Hash.new
          event[:title] = "#{workitem.params['step']}:: #{email[:subject]}"
          event[:desc] = "#{email[:body]}"
          SMGoogleCalendar.create_event( event )
        rescue Exception => e
          puts "decode_workitem error: #{e.message}"
        end
        print "#{@blue_underline}3.listener processed workitem:#{@normal} #{workitem}\n"
        workitem
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
