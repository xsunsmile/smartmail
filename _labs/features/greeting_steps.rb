
class MyGreeter

    def hello
        "Hello Cucumber!"
    end
end

Given /^a greeter$/ do
    @greeter = MyGreeter.new
end

When /^i send it the hello message$/ do
    @message = @greeter.hello
end

Then /^it should say "([^\"]*)"$/ do |message|
    @message.should == message
end
