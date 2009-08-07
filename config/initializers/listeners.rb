
require 'ruby-debug'
require 'lib/smartmail_listener'

if RuotePlugin.ruote_engine
  # only enter this block if the engine is running

  # This is a test participant
  #
  # Feel free to comment it out / erase it
    #

    RuotePlugin.ruote_engine.register_listener(
      OpenWFE::Extras::SmartmailListener.new('MailAgentListener', 'emails_store'=>'tmp/emails'), 
      :frequency => '60000'
    )

end

