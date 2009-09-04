
require 'smartmail_settings'

sets = SMSetting.load
mail = sets['smartmail']['user_name']
pass = sets['smartmail']['user_password']
@@srv = GoogleCalendar::Service.new(mail, pass)
feed_root = "http://www.google.com/calendar/feeds"

cals = sets['smartmail']['calendars']
cal = cals.find {|it| it['name'] == "孫コウ" }
read_write = "private/full"
feed = "#{feed_root}/#{cal['ident']}/#{read_write}"
# read_write = "private-42d02235f60d33aa9f07660c8a4f855e/basic"
cal = GoogleCalendar::Calendar::new(@@srv, feed)
event = cal.create_event
event.title = 'test'
event.desc = "test"
event.where = ""
event.st = Time.now
event.en = Time.now
event.save!

