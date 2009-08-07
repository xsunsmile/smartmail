require 'rubygems'
require 'openwfe/engine/file_persisted_engine' # sudo gem install ruote

engine = OpenWFE::FilePersistedEngine.new(
  :definition_in_launchitem_allowed => true)

#
# the process definition

class MyTodoProcess < OpenWFE::ProcessDefinition
  cursor do
    perform_task
    continue :unless => "${f:over}"
  end
end

#
# the participant

engine.register_participant :perform_task do |workitem|
  p workitem
  puts
  puts "  done :"
  workitem.done.each do |task, time|
    puts "- #{task} - #{time}"
  end
  puts
  puts "  todo :"
  workitem.todo.each_with_index do |task, i|
    puts "#{i}) #{task}"
  end
  puts
  print "task # (n for new, x for exit) ==> "
  i = gets.strip
  if i == 'n'
    print "new task : "
    workitem.todo << gets.strip
  elsif i == 'x'
    exit 0
  else
    t = workitem.todo.delete_at(i.to_i)
    workitem.done << [ t, Time.now.to_s ] if t
  end
  workitem.over = (workitem.todo.size == 0)
end

#
# process already running ?

ps = engine.process_statuses.values[0]

fei = if ps

  #
  # yes, there is already a running process, resume it...

  engine.replay_at_error(ps.errors.values[0])

  puts "using already launched process..."

  sleep 0.350

  ps.wfid

else

  #
  # no process running, launch a new one...

  li = OpenWFE::LaunchItem.new(MyTodoProcess)
  li.goal = "meeting preparation"
  li.todo = [
    "reserve room",
    "reserve beamer",
    "send invitations",
    "order sandwiches"
  ]
  li.done = []

  engine.launch(li)

end

#
# don't exit before the process is over

engine.wait_for(fei)

