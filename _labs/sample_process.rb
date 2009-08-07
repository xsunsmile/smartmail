
require 'openwfe/engine' # sudo gem install ruote

process_definition = OpenWFE.process_definition :name => 'JobRequest' do
  sequence do
    participant :ref => 'owner', :step => 'determine_workers'
    participant :ref => 'owner', :step => 'decide_job_details'
    cursor :rewind_if => '${f:rework}', :break_if => '${f:cancel}' do
      concurrent_iterator :on => "${f:workers}", :to_field => 'worker', :merge_type => 'isolate' do
        repeat do
          participant :ref => 'print', :step => 'send_job'
          _break :unless => "${f:question}"
          participant :ref => 'print', :step => 'help'
          participant :ref => 'print', :step => 'answer'
        end
      end 
      participant :ref => 'owner', :step => 'aggregate_results'
      participant :ref => 'owner', :step => 'receive_report'
    end
    participant :ref => 'owner', :step => 'cancel_process', :if => '${f:cancel}'
  end
end

engine = OpenWFE::Engine.new(:definition_in_launchitem_allowed => true)
fei = engine.launch(process_definition)
engine.wait_for(fei)
