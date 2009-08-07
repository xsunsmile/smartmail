
require 'kconv'
require 'yaml'
require 'pp'

reply_to = "smart.mailflow@gmail.com".split(/@/)
wfid = "test_wfid"
p "reply_to: #{reply_to[0]}+#{wfid}@#{reply_to[1]}"

str = ">:20090712-juhotaredi::\r"
str2 = "-------"
pattern = /(:*)([\d]+-[a-z]+)(:*)/
puts $2 if /#{pattern}/ =~ str
puts $2 if /#{pattern}/ =~ str2

str = "      >====== 業務依頼 ======\r"
pattern = /(=+)\s([(?=\s)\W]+)\s(=+)/
	p "ttt: #{$2.gsub(/=/,'')}" if /#{pattern}/ =~ str
	puts Kconv.toutf8($2.gsub(/=/,'')) if /#{pattern}/ =~ str

	config = YAML.load_file("../config/config.yml")
	controller = config['action_type']
	temp = Hash.new
	controller.each_pair do |role, actions|
	temp[role] = actions
	temp[role] = actions.merge(controller['all']) if role != 'all'
	end

	role = 'owner'
	role = 'all'
	message = ''

	temp[role].keys.sort.each do |key|
	details = temp[role][key]
	order = $1 if /_(\d*)_/ =~ key
	extra_reply_code = "#{details['short_form']}_#{wfid}"
	desc = Kconv.toutf8(details['description'])
	message += "#{extra_reply_code} for #{order}.#{desc}\n"
	end

pp message.split(/\n/)

