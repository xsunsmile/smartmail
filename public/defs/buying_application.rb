
class BuyingApplication < OpenWFE::ProcessDefinition

  description "買い物申請"

  sequence do
    cursor :rewind_if => '${f:rework}', :break_if => '${f:cancel}' do
      participant :ref => 'owner', :step => 'decide_item'
      participant :ref => 'owner', :step => 'determine_workers'
      participant :ref => 'set_timeout', :step => 'send_request'
      concurrent_iterator :on => "${f:workers}", :to_field => 'worker', 
      :merge_type => 'isolate', :timeout => '${f:timeout}' do
        repeat :break_if => '${f:cancel}' do
          participant :ref => '${f:worker}', :step => 'send_request'
          _break :unless => "${f:question}"
          participant :ref => 'owner', :step => 'ask_a_question'
          participant :ref => '${f:worker}', :step => 'forward_answer'
          participant :ref => 'poll', :args => 'v:positiveAnswers,l:positiveMust,b:polling_break'
          _break :if => "${f:polling_break}"
        end
      end
      _if :test => "${f:positiveAnswers} < ${f:positiveMust}" do
        participant :ref => 'owner', :step => 'aggregate_results'
        repeat :break_if => '${f:cancel}' do
          participant :ref => 'professor', :step => 'beg_for_permission'
          _break :unless => "${f:question}"
          participant :ref => 'owner', :step => 'ask_a_question'
          participant :ref => 'professor', :step => 'forward_answer'
        end
      end
      _if :test => "${f:professorDeny}" do
        participant :ref => 'owner', :step => 'forward_result'
        sequence do
          participant :ref => 'secretaries', :step => 'buy_item'
          participant :ref => 'professor', :step => 'buy_item'
        end
      end
    end
    participant :ref => 'owner', :step => 'cancel_process', :if => '${f:cancel}'
  end

end
