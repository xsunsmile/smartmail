
require 'rubygems'
require 'webrat'

def test_sign_up
    visit "http://dev.milog.jp:3000/session/new/" 
    fill_in "username", :with => "admin" 
    fill_in "password", :with => "admin"
    click_link "Log in" 
    # select "Free account" 
    # click_button "Register" 
end

test_sign_up
