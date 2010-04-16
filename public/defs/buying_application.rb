
class JobRequest < OpenWFE::ProcessDefinition

  description "買い物申請"

  sequence do
    cursor :rewind_if => '${f:rework}', :break_if => '${f:cancel}' do
      participant :ref => 'owner', :step => 'determine_workers'
      participant :ref => 'owner', :step => 'decide_job_details'
      participant :ref => 'set_timeout', :step => 'send_job'
      concurrent_iterator :on => "${f:workers}", :to_field => 'worker', 
      :merge_type => 'isolate', :timeout => '${f:timeout}' do
        repeat :break_if => '${f:cancel}' do
          participant :ref => '${f:worker}', :step => 'send_job'
          _break :unless => "${f:question}"
          participant :ref => 'owner', :step => 'ask_a_question'
          participant :ref => '${f:worker}', :step => 'forward_answer'
        end
      end 
      participant :ref => 'owner', :step => 'aggregate_results'
      participant :ref => 'owner', :step => 'receive_report'
    end
    participant :ref => 'owner', :step => 'cancel_process', :if => '${f:cancel}'
  end

end
