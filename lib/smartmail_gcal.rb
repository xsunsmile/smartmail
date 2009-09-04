
require 'gcalapi'
require 'smartmail_settings'

class SMGoogleCalendar

  @@cal, @@sev, @@feed = nil, nil, nil

  def self.open_calendar
    puts "open_calendar"
    settings = SMSetting.load
    mail = settings['smartmail']['user_name']
    pass = settings['smartmail']['user_password']
    feed_root = "http://www.google.com/calendar/feeds/#{mail.sub(/@/,'%40')}"
    read_only = "private-fcde53caff5aa60f7a391985055611dd/basic"
    read_write = "private/full"
    @@feed = "#{feed_root}/#{read_write}"
    @@srv = GoogleCalendar::Service.new(mail, pass)
    @@cal = GoogleCalendar::Calendar::new(@@srv, @@feed)
  end

  def self.list_events
    open_calendar unless @@cal
    events = @@cal.events
    events.each do |event|
      puts "#{event.title} #{event.where} #{event.desc}"
      all_day = event.allday
      str_format = (all_day)? "%Y-%m-%d" : "%Y-%m-%d %H-%M-%S"
      start_time = Time.at(event.st.to_f).strftime( str_format )
      end_time = Time.at(event.en.to_f).strftime( str_format )
      puts (all_day)? "all day #{start_time} -> #{end_time}" : "#{start_time} -> #{end_time}"
    end
  end

  def self.list_events_by_query( query )
    open_calendar unless @@srv
    events = @@srv.query( feed, :"max-results" => 5 )
    puts events
  end

  def self.create_event( new_event )
    open_calendar unless @@cal
    event = @@cal.create_event
    event.title = new_event[:title]
    event.desc = new_event[:desc]
    event.where = new_event[:where] || ""
    event.st = new_event[:start] || Time.now
    event.en = new_event[:end] || Time.now
    event.save!
  end

end
