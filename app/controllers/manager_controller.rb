require 'yaml'

class ManagerController < ApplicationController

    def distribute
        # settings = YAML.load_file('config/config.yml')
        # params = settings["smartmail"]
        jmail = JMail.new()
        jmail.set_to('xsunsmile@gmail.com')
        jmail.set_subject('$BF|K\8l%?%$%H%k(B')
        jmail.set_text('test message')
        jmail.set_attach('$B%a!<%kAw?.(B.txt')
        jmail.send
        render :text => "<pre> #{params} </pre>";
    end

end
