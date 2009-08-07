
require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new                     # インスタンス生成
agent.user_agent_alias = 'Mac Safari'          #  User-Agentの設定
page = agent.get('http://dev.milog.jp:3000/session/new')     # ページ取得

login_form = page.forms.first
login_form.login = 'admin'
login_form.password= 'admin'
workitems_list = agent.submit(login_form)

defination_page_link = workitems_list.links.find { |link| link.text =~ /definitions/ }
definations = defination_page_link.click()

job_request_workflow_link = definations.links.find { |link| link.text =~ /Job Request/ }
jr_workflow_defid = $1 if /definitions\/(\d*)/ =~ job_request_workflow_link.href
jr_launch_link = definations.links.find { |link| 
    link.text == 'launch' && link.href == "/processes/new?definition_id=#{jr_workflow_defid}" 
}
jr_process = jr_launch_link.click
launch_form = jr_process.forms.first
# launch_form.fields = ''
jr_result = agent.submit( launch_form )
p jr_result
