
OpenWFE.process_definition :name => 'v1' do
  concurrent-iterator :on => "a, b, c, d", :to_field => 'worker'
    repeat do
      participant :ref => '${f:worker}'
      _break :unless => '${f:question}'
      participant :ref => 'help'
    end
  end
end

OpenWFE.process_definition :name => 'v1' do
  sequence do
    participant :ref => 'determine_workers'
    concurrent-iterator :on => '${f:workers}', :to_field => 'worker', :merge_type => 'isolate' do
      repeat do
        participant :ref => '${f:worker}'
        _break :unless => '${f:question}'
        participant :ref => 'help'
      end
    end
    participant :ref => 'aggregate_results'
  end
end
