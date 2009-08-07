require 'rubygems'
require 'kconv'
require "../lib/google_spreadsheet"

# Logs in.
username = "smart.mailflow@gmail.com"
password = "gks-smartmail"
# First worksheet of http://spreadsheets.google.com/ccc?key=${spreadsheet_key}&hl=en
spreadsheet_key = "teWT4QPacwHDzWdReBtrekw"

session = GoogleSpreadsheet.login( username, password )
spreadSheet = session.spreadsheet_by_key( spreadsheet_key )

# get dance blog data
dance = spreadSheet.worksheets[0]
dance_data = dance.rows.dup
dance_title = dance_data.shift

dance_data.each do |row|
  puts ''
  dance_title.each_index do |idx|
	  str = Kconv.toutf8(dance_title[idx])
	  pattern = Kconv.toutf8("仕事依頼先")
	  puts "#{dance_title[idx]}: #{row[idx]}" if pattern == str
	  pattern = Kconv.toutf8("依頼先メール")
	  puts "#{dance_title[idx]}: #{row[idx]}" if pattern == str
  end
end

# Gets content of A2 cell.
# print "#{ws[2, 3]} \n" #==> "hoge"

# Changes content of cells. Changes are not sent to the server until you call ws.save().
# ws[2, 1] = "foo"
# ws[2, 2] = "bar"
# ws.save()

# Reloads the worksheet to get changes by other clients.
# ws.reload()

