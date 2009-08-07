
class MyGreeter

 def hello
    'Hello Test'
 end

end

describe "Hello Test" do
 it "should say hello when hello() is called" do
   greeter = MyGreeter.new
   greeting = greeter.hello
   greeting.should == 'Hello Test'
 end
end

