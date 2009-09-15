
class InterSAdvice < OpenWFE::ProcessDefinition

  description "InterS Advices"

  repeat do
      participant :ref => 'owner', :step => 'send_advices'
      participant :ref => 'owner', :step => 'accept', :if => '${f:accept}'
      participant :ref => 'owner', :step => 'discard', :if => '${f:discard}'
  end

end
