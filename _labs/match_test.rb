
require 'pp'

str = '�ڶ�̳����::qyZSWf63Rx54iaT5�����ܸ�ƥ���'

pattern = /::([[:print:]-]*)/
str = '�ڶ�̳����::20090626-gedizasamo��20090629-ssedizasamo'

pattern = /<(.*)@(.*)>:/
str = '2009/06/26 20:32 <smart.mailflow@gmail.com>:'

pattern = />(.*)::([[:print:]-]*)(.*)/
str = '> ##### ��̳����::20090626-hijapegeha #####'

pattern = /^[\x01-\x7F]+@(([-a-zA-Z0-9]+\.)*[a-zA-Z]+|\[\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\])/

str = 'xsun+xsunsmile@gmail.com'
p str if /#{pattern}/ =~ str
    
str = '_onew'
p str if /#{pattern}/ =~ str
