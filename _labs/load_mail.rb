
require 'rubygems'
require 'tmail'
require 'pp'

mail = TMail::Mail.load("../mail.eml")

if mail.multipart? then
    mail.parts.each do |m|
        puts m.content_type
        puts "#{'#'*20}\n #{m.body}\n #{'#'*20}"
    end
end
