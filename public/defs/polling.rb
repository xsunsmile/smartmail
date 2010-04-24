
class BuyingApplicationML < OpenWFE::ProcessDefinition

  description "投票のお願い"

  sequence do
    cursor :rewind_if => '${f:rework}', :break_if => '${f:cancel}' do
      participant :ref => 'owner', :step => 'decide_item'
      participant :ref => 'set_timeout', :step => 'send_request'
      concurrent_iterator :on => "${f:workers}", :to_field => 'worker', 
      :merge_type => 'isolate', :timeout => '${f:timeout}' do
        repeat :break_if => '${f:cancel}' do
          _break :if => "${f:positiveAnswers} >= ${f:positiveMust}"
          participant :ref => '${f:worker}', :step => 'send_request'
          _break :unless => "${f:question}"
          participant :ref => 'owner', :step => 'ask_a_question'
          participant :ref => '${f:worker}', :step => 'forward_answer'
        end
      end
      participant :ref => 'owner', :step => 'aggregate_results', :if => "${f:positiveAnswers} < ${f:positiveMust}"
      repeat :break_if => '${f:cancel}' do
        participant :ref => 'professor', :step => 'beg_for_permission'
        _break :unless => "${f:question}"
        participant :ref => 'owner', :step => 'ask_a_question'
        participant :ref => 'professor', :step => 'forward_answer'
      end
      participant :ref => 'owner', :step => 'forward_result'
      _break :if => "${f:professorDeny}"
      participant :ref => 'secretaries', :step => 'buy_item'
      participant :ref => 'professor', :step => 'buy_item'
    end
    participant :ref => 'owner', :step => 'cancel_process', :if => '${f:cancel}'
  end

end
