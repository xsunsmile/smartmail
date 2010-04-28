
class BuyingApplicationNoVote < OpenWFE::ProcessDefinition

  description "買い物申請 投票なし版"

  sequence do
    cursor :rewind_if => '${f:rework}', :break_if => '${f:cancel}' do
      participant :ref => 'owner', :step => 'decide_item'
      participant :ref => 'set_timeout', :step => 'beg_for_permission'
      repeat :break_if => '${f:cancel}' do
        participant :ref => 'professor', :step => 'beg_for_permission'
        _break :unless => "${f:question}"
        participant :ref => 'owner', :step => 'ask_a_question'
        participant :ref => 'professor', :step => 'forward_answer'
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
