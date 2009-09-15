
require 'gcalapi'
require 'smartmail_settings'

class SMGoogleCalendar

  @@cals, @@sev, @@feed_root, @@smartmail_cal, @@settings = [], nil, nil, nil, nil

  def self.load_settings
    puts "open_calendar"
    @@settings = SMSetting.load
    mail = @@settings['smartmail']['user_name']
    pass = @@settings['smartmail']['user_password']
    @@srv = GoogleCalendar::Service.new(mail, pass)
    @@feed_root = "http://www.google.com/calendar/feeds/__USER__/private/full"
  end

  def self.open_calendar
    load_settings unless @@settings
    cals = @@settings['smartmail']['calendars']
    cals.each do |cal|
      cal_name = cal['name']
      feed = @@feed_root.sub(/__USER__/, cal['ident'])
      cal_obj = GoogleCalendar::Calendar::new(@@srv, feed)
      @@cals << { :name => cal_name, :cal => cal_obj }
    end
    @@smartmail_cal = @@cals.find {|it| it[:name] == 'default' }[:cal]
    # p @@cals, @@smartmail_cal
  end

  def self.calendars
    open_calendar unless @@cals.size > 0
    @@cals
  end

  def self.list_events
    open_calendar unless @@smartmail_cal
    events = @@smartmail_cal.events
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
    # events = @@srv.query( feed, :"max-results" => 5 )
    # puts events
  end

  def self.create_event( new_event, username = "default" )
    open_calendar unless @@cals.size > 0
    cal_item = @@cals.find {|it| it[:name] == username }
    cal = (cal_item)? cal_item[:cal] : @@smartmail_cal
    begin
      event = cal.create_event
      event.title = new_event[:title]
      event.desc = new_event[:desc]
      event.where = new_event[:where] || ""
      event.st = new_event[:start] || Time.now
      event.en = new_event[:end] || Time.now
      event.save!
    rescue Exception => e
      return e.message
    end
  end

end
