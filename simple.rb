
require 'rubygems'
require 'openwfe/engine' # sudo gem install ruote

#
# define a process, just a sequence, from Alice to Bob

process_definition = OpenWFE.process_definition :name => 'test' do
  sequence do
    participant 'alice', :timeout => '3d'
    participant 'bob'
  end
end

#
# instantiate a ruote engine, the default (transient) one is OK.
# allow it to fetch process definitions from lauchitems.
#
# more info about engines and persistence flavour at
#
# http://openwferu.rubyforge.org/persistence.html

engine = OpenWFE::Engine.new(:definition_in_launchitem_allowed => true)

#
# register two very basic participants 'alice' and 'bob',
# use a BlockParticipant (simply wrapping some ruby code inside of a
# participant).
#
# more info about participants at
#
# http://openwferu.rubyforge.org/participants.html

engine.register_participant 'alice' do |workitem|
  puts '~alice~'
  workitem.params['timeout'] = '1d'
  workitem.fields['message'] = 'hello from Alice !'
  print workitem
end
engine.register_participant 'bob' do |workitem|
  puts '~bob~'
  puts "the message says '#{workitem.fields['message']}'"
  print workitem
end

#
# launch the process (let the engine interpret the process definition and
# create a process instance)

fei = engine.launch(process_definition)

#
# wait for the process instance to terminate before exiting this tiny ruby
# program

engine.wait_for(fei)

