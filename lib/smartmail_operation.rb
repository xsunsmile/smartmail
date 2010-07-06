
require 'date'
require 'kconv'
require 'rufus/scheduler'
require 'lib/smartmail_spreadsheet'
require 'lib/smartmail_settings'

class SMOperation

  @@list_prefix = '<'
  @@list_pair_join_character = ' , '
  @@separator = "__sm_sep__"

  @@list_select_st = "\n{field_start}\n"
  @@list_select_ed = "\n{field_end}\n"

  @@underline = [0x1B].pack("c*") + "[1;4;35m"
  @@normal = [0x1B].pack("c*") + "[0m\n"

  # set info between step_information and workitems
  def self.operate( workitem )
    return unless workitem
    step_information = get_step_information_from_workitem( workitem )
    # puts "step_information: #{step_information}"
    return unless step_information
    underline = [0x1B].pack("c*") + "[1;4;32m"
    information = Hash.new
    step_information.each {|it| information[it[:title]] = it[:contents]}
    get_operations( step_information ).each do |oper|
      field, operation, operands = oper[:field], oper[:operation], oper[:operands]
      puts "#{underline}f:#{field} oper:#{operation} opera:#{operands}#{@@normal}"
      next unless field && operation && operands
      result = get_operation_results( operation, operands, workitem )
      replace = "\{#{operation}:#{operands}\}"
      set_operation_contents( information, field, { replace => result })
    end
    # information.each_pair {|k,v| puts "step_information: #{underline}#{k} --> #{v}#{@@normal}" }
    information
  end

  def self.build( email, workitem )
    return unless email
    mail_to, body = email[:to], email[:body]
    workitem.fields['__sm_build__'] = body
    next_step = get_step_information_from_email( email, workitem )
    workitem.fields['__sm_option__'] = next_step if next_step
    operate( workitem )
  end

  def self.get_step_information( process_name, step_name )
    sheet_name = process_name + '_steps'
    puts "get_step_information: get sheet, #{sheet_name}, step: #{step_name}"
    fields = SMSpreadsheet.get_fields_from_spreadsheet( sheet_name )
    step_field = nil
    fields.each do |f|
      contents = f[:contents]
      # puts "conts: #{contents}, step_name: #{step_name}"
      step_name_in_spreadsheet = $2 if /\{sm_step(_short)?:(.*)\}/ =~ contents
      next unless step_name_in_spreadsheet
      if step_name_in_spreadsheet == step_name
        step_field = f
        break
      end
    end
    this_stepinfo = fields.collect{|f| f if f[:row] == step_field[:row] }
    this_stepinfo.compact! if this_stepinfo
    # puts "this_stepinfo: #{this_stepinfo.inspect}"
    this_stepinfo
  end

  protected

  def self.set_operation_contents( step_information, field, contents )
    return unless contents
    field = Kconv.toutf8( field )
    pre_cont = step_information[field]
    if pre_cont.is_a? String
      step_information[field] = Hash.new
      step_information[field]['pre_contents'] = pre_cont
      step_information[field]['replace_contents'] = Array.new
    end
    step_information[field]['replace_contents'] << contents
  end

  def self.get_step_information_from_workitem( workitem )
    process_name = workitem.fei.wfname
    step = workitem.params["step"].gsub(/\"/,'') if workitem.params["step"]
    # puts "step is #{step}"
    step_information = get_step_information( process_name, step )
    step_information
  end

  def self.get_operations( step_information )
    operations = Array.new
    step_information.sort_by{|it|it[:column]}.each do |field|
      operation_str = field[:contents]
      operation_str.scan(/\{(sm_\w+):(.*)\}/).each do |oper|
        _oper, operands = oper[0], oper[1]
        #puts "get_operations f:#{field} ==> #{_oper},#{operands}"
        operations << { :field => field[:title], :operation => _oper, :operands => operands }
      end
    end
    operations
  end

  def self.get_step_information_from_email( email, workitem )
    mail_to = email[:to]
    return unless mail_to
    next_step = $1 if /\+([a-z]*)?_?(\d+)@/ =~ mail_to
    next_step
  end

  def self.reply_quotation_starts( message )
    _message = message.to_s.chomp
    docomo_reply_pattern = /^>$/
      marker_pattern = />(:*)(\d+-\w+)(:*)|>(#+)\s(.*)\s(#+)/
      cell_phone_pattern = /^On [\d\/]*, at/
      gmail_pattern = /<(.*)@(.*)>:/
      gmail_pattern2 = /--[0-9a-z]+--/
      /#{gmail_pattern}/ =~ _message or
      /#{gmail_pattern2}/ =~ _message or
      /#{marker_pattern}/ =~ _message or 
      /#{cell_phone_pattern}/ =~ _message or
      /#{docomo_reply_pattern}/ =~ _message
  end

  def self.delete_reply_qoutations( message )
    return unless message
    result = Array.new
    message.split(/\n/).each do |line|
      puts "reply start: #{line}" if reply_quotation_starts( line )
      break if reply_quotation_starts( line )
      result << line
    end
    result.join("\n")
  end

  def self.fill_operation_result( description, workitem )
    return unless description && description.to_s.size > 0
    description.scan(/\{(sm_\w+):(.*)\}/).each do |oper|
      operation, operands = oper[0], oper[1]
      result = get_operation_results( operation, operands, workitem ) || "No result for #{operation}:#{operands}"
      description.sub!(/\{#{operation}:#{operands}\}/,result)
        # puts "#{@@underline}oper:#{operation} opera:#{operands} res:#{description}#{@@normal}"
    end
    description
  end

  def self.get_operation_results( operation, operands, workitem )
    return unless operation.to_s.size > 0 && operands.to_s.size > 0 && workitem
    result = ''
    _method = self.methods.find {|m| m == operation }
    return unless _method
    result = self.method(_method).call( operation, operands, workitem )
    result
  end

  def self.change_string_to_time( format )
    return_time = DateTime.now
    # puts return_time.strftime("%Y-%m-%d %H:%M:%S")
    patterns = [ /(\d*)(y)/, /(\d*)(m)/, /(\d*)(d)/, /(\d*)(H)/, /(\d*)(M)/, /(\d*)(S)/ ]
    patterns.each do |pattern|
      diff, kinds = $1.to_i, $2 if /#{pattern}/ =~ format
        case kinds
        when 'y' 
          return_time = return_time >> diff * 12
        when 'M' 
          return_time = return_time >> diff
        when 'd' 
          return_time += diff
        when 'h' 
          return_time += Rational(diff,24)
        when 'm' 
          return_time += Rational(diff,24*60)
        when 's' 
          return_time += Rational(diff,24*60*60)
        end 
    end 
    # puts "#{format}, #{return_time.strftime("%Y-%m-%d %H:%M:%S")}"
    return_time
  end


  def self.sm_timeout( operation, operands, workitem )
    return unless workitem
    timeout_at = Time.at(Rufus.parse_time_string(operands))
    timeout_at.strftime("%Y/%m/%d %H:%M:%S")
  end

  def self.sm_reminder( operation, operands, workitem )
    return unless workitem
    times = operands.split(/,/)
    s_reminder = workitem.fields['__sm_reminder__']
    unless s_reminder
      s_reminder = times[0]
      workitem.fields['__sm_reminder__'] = s_reminder
    end
    s_timeout = workitem.fields['__sm_timeout__']
    unless s_timeout
      s_timeout = times[1]
      workitem.fields['__sm_timeout__'] = s_timeout
    end
    f_now = Time.now.to_f
    reminder_at = Time.at(f_now + Rufus.parse_time_string(s_reminder))
    timeout_at = Time.at(f_now + Rufus.parse_time_string(s_timeout))
    "#{s_reminder}, #{timeout_at.strftime("%Y/%m/%d %H:%M:%S")}"
  end

  def self.sm_step( operation, operands, workitem )
    operands
  end

  def self.sm_set_true( operation, operands, workitem )
    operands.split(/,/).each do |field|
      workitem.fields[ field ] = true
    end
    return
  end

  def self.sm_del( operation, operands, workitem )
    operands.split(/,/).each do |field|
      pre_item = workitem.fields[ field ]
      workitem.fields[ "__#{field}_#{Time.now.to_f}" ] = pre_item
      workitem.fields[ field ] = nil
    end
    return
  end

  def self.sm_ref( operation, operands, workitem )
    results = Hash.new
    operands.split(/,/).each do |step|
      next unless step
      process_name = workitem.fei.wfname
      step_information = get_step_information( process_name, step )
      _results = Hash.new
      selection_fields = SMFormater.get_reply_options.values
      SMFormater.get_reply_options.values.each do |field|
        value = step_information.find {|f| f[:title] == field }
        value = fill_operation_result( value[:contents], workitem )
        _results[field] = value
      end
      results[ step ] = _results
    end
    results.each_pair {|k,v| 
      # puts "#{@@underline}sm_ref in step:#{k}, #{v.collect{|_k,_v|"#{_k}:#{_v}"}.join(' , ')}#{@@normal}" 
    }
    return results
  end

  def self.sm_step_short( operation, operands, workitem )
    fei_store_id = workitem.fields['fei_store_id']
    raise "sm_step_short: can not get fei_id" unless fei_store_id
    extra_reply_code = "#{operands}_#{fei_store_id}"
    settings = SMSetting.load
    from_address = settings["smartmail"]["from_address"]
    reply_to = from_address.split(/@/)
    "#{reply_to[0]}+#{extra_reply_code}@#{reply_to[1]}"
  end

  def self.sm_get( operation, operands, workitem )
    message = ''
    operands.split(/,/).each do | field |
      field, default_value = $1, $2 if field =~ /(.*)\.(.*)/
      info = workitem.fields[ field ].to_s || ''
      info = delete_reply_qoutations( info ) || ''
      info = info.split(@@separator).join("\n")
      info = default_value unless info.size > 0
      puts "sm_get: #{field} --> #{info} , #{default_value}"
      message += info.to_s
    end
    message
  end

  def self.sm_aggregate( operation, operands, workitem )
    # print "sm_aggregate in: #{workitem}\n"
    workitem.attributes.each do |_attr|
      is_hash = (_attr.is_a? Array) && (_attr.size%2 == 0) || (_attr.is_a? Hash)
      # p "sm_aggregate: attr: #{_attr.inspect}" if is_hash
      _cont = Hash[*_attr] if is_hash
      next unless _cont.is_a? Hash
      _cont.values.each do |_hash|
        another_hash = (_hash.is_a? Hash) || (_hash.is_a? HashWithIndifferentAccess)
        # p "sm_aggregate0: _hash:#{_hash.class}, #{_hash.inspect}" if another_hash
        next unless another_hash
        operands.split(/,/).each do |set_field|
          info_from = (_hash[set_field].is_a? Array)? _hash[set_field].join(" ") : (_hash[set_field] || '')
          info = info_from.to_s.chomp || ''
          next unless info.size > 0
          pre_info, new_info = workitem.fields[ set_field ], info
          _pre_info = pre_info.to_s.gsub(@@separator){''} if pre_info
          store_info = ( _pre_info =~ /#{new_info}/ )? pre_info : "#{pre_info}#{@@separator}#{new_info}"
          store_info = _pre_info.to_i + new_info.to_i if (_pre_info =~ /^\d+$/ && new_info =~ /^\d+$/)
          puts "sm_aggregate: set #{set_field} --> #{store_info}"
          workitem.fields[ set_field ] = store_info
        end
      end
    end
    return nil
  end

  def self.sm_set( operation, operands, workitem )
    data = workitem.fields['__sm_build__']
    return unless data
    data = delete_reply_qoutations( data )
    workitem.fields[ operands ] = data
    workitem.fields['__sm_build__'] = ''
    return
  end

  def self.sm_get_polling_result( operation, operands, workitem )
    return unless workitem
    wfid, polling_value = workitem.fei.wfid, 0
    operands.split(/,/).each do |item|
      Poll.find_all_by_wfid( wfid ).each do |poll_item|
        polling_value = polling_value + 1 if poll_item.polling_name.to_s == item
      end
      workitem.fields[ "polling_#{item}" ] = polling_value
      message = "sm_get_polling_result #{item} == #{polling_value}"
      puts "\n#{@@underline}#{message}#{@@normal}"
    end
    return
  end

  def self.sm_add_polling_if( operation, operands, workitem )
    return unless workitem
    user_chose_step = workitem.fields['__sm_option__']
    user_chose_step = workitem.params["step"] unless user_chose_step
    return unless user_chose_step
    operands.split(/,/).each do |cond|
      condition, set_field = $1, $2 if /(\w*)_(\w*)/ =~ cond
      puts "\nsm_add_polling_if user_step:#{user_chose_step} == con:#{condition}"
      next unless condition == user_chose_step
      set_value = (workitem.fields[ set_field ] || '0').to_i + 1
      poll_item = Poll.new
      poll_item.fei = workitem.fei
      poll_item.wfid = workitem.fei.wfid
      poll_item.polling_name = set_field
      poll_item.polling_value = set_value
      poll_item.mailitem_id = workitem.fields[ "fei_store_id" ]
      poll_item.username = workitem.fields[ "user_name" ]
      poll_item.email_from = workitem.fields[ "email_from" ]
      poll_item.save!
      workitem.fields[ set_field ] = set_value
      message = "sm_add_polling_if set:#{set_field} --> v:#{set_value}"
      puts "\n#{message}"
    end
    return
  end

  def self.sm_set_if( operation, operands, workitem )
    data = workitem.fields['__sm_build__']
    user_chose_step = workitem.fields['__sm_option__']
    user_chose_step = workitem.params["step"] unless user_chose_step
    worker = workitem.fields['worker']
    data = delete_reply_qoutations( data )
    underline = [0x1B].pack("c*") + "[1;4;31m"
    message = "#{worker}sm_set_if user_step:#{user_chose_step} data:#{data} info:#{operands}"
    # puts "#{underline}#{message}#{@@normal}"
    return unless data && data.to_s.size > 0
    data.chomp!
    return unless data && data.to_s.size > 0
    operands.split(/,/).each do |cond|
      condition, true_field, false_field = $1, $2, $3 if /(\w*)_(\w*)_(\w*)/ =~ cond
      set_field = ( condition == user_chose_step )? true_field : false_field
      unset_field = ( set_field == true_field )? false_field : true_field
      set_value = ( data.size > 0 )? data : true
      message = "#{@@underline}sm_set_if user_step:#{user_chose_step} == con:#{condition}, set:#{set_field}, v:#{set_value}, unset:#{unset_field} #{@@normal}"
      workitem.fields[ set_field ] = set_value
      #TODO: to just to cancel, not also report if 'cp'
      workitem.fields[ unset_field ] = nil
      puts "#{underline}#{worker}#{message}#{@@normal}"
      workitem.fields['__sm_build__'] = ''
      workitem.fields['__sm_option__'] = ''
    end
    return nil
  end

  #TODO: select by department and role
  def self.sm_select( operation, operands, workitem )
    underline = [0x1B].pack("c*") + "[1;4;31m"
    data = workitem.fields['__sm_build__']
    return unless data
    pattern = /\{.*_start\}(.*)\{.*_end\}/
    data.gsub!(/\r\n|\r|\n|<br>/,'[NEWLINE]').gsub!(/>/,'')
    # puts "#{underline}sm_select#{@@normal} from data: #{data}"
    selection = data.scan( pattern ).join('').split(/\[NEWLINE\]/).collect {|pp| pp if !(/#{@@list_prefix}/ =~ pp) }.compact!
    selection.each {|it| it.gsub!(/\[NEWLINE\]/,"\n")}
    return unless selection
    selected_items = selection.collect {|item| item.gsub!(/\s/,''); item + "," if item.size > 0 }.compact
    # puts selected_items
    workitem.fields[ operands ] = selected_items
    workitem.fields['__sm_build__'] = ''
    return
  end

  #TODO: select by department and role
  def self.sm_select_if( operation, operands, workitem )
    underline = [0x1B].pack("c*") + "[1;4;31m"
    data = workitem.fields['__sm_build__']
    return unless data.to_s.size > 0
    pattern = /\{.*_start\}(.*)\{.*_end\}/
    data.gsub!(/\r\n|\r|\n|<br>/,'[NEWLINE]').gsub!(/>/,'')
    # puts "#{underline}sm_select_if#{@@normal} from data: #{data}"
    selection = data.scan( pattern ).join('').split(/\[NEWLINE\]/).collect {|pp| pp if !(/#{@@list_prefix}/ =~ pp) }.compact!
    selected_items = 
      selection.collect {|item| item.gsub!(/\s|&nbsp;|　/,''); item + "," if item.size > 0 }.compact if selection
    data.gsub!(/\[NEWLINE\]/,"\n")
    field_value = (selected_items)? selected_items : true
    user_chose_step = workitem.fields['__sm_option__']
    user_chose_step = workitem.params["step"] unless user_chose_step
    # puts "#{underline}sm_select_if: selection:#{selected_items} user_chosen:#{user_chose_step}#{@@normal}"
    # puts selected_items
    operands.split(/,/).each do |cond|
      condition, true_field, false_field = $1, $2, $3 if /(\w*)_(\w*)_(\w*)/ =~ cond
      #TODO: to just to cancel, not also report if 'cp'
      set_field = ( condition == user_chose_step )? true_field : false_field
      message = "sm_select_if user_step:#{user_chose_step} == con:#{condition}, f:#{set_field}, v:#{field_value}"
      # puts "#{underline}#{message}#{@@normal}"
      workitem.fields[ set_field ] = field_value # unless workitem.fields[ set_field ]
    end
    workitem.fields['__sm_build__'] = ''
    workitem.fields['__sm_option__'] = ''
    return
  end

  def self.sm_sheetref_list( operation, operands, workitem )
    message = ''
    params = operands.split(/,/)
    sheet_name, field = params[0], params[1]
    return unless sheet_name.size > 0 && field.size > 0
    raw_data = SMSpreadsheet.get_columns_from_spreadsheet( sheet_name, field )
    raw_data.uniq!
    # puts raw_data
    value = raw_data.collect { |v| "#{v}," }
    value << value.pop.gsub(/,/,'')
    # p value
    message += @@list_select_st.gsub(/field/, field)
    value.each { |v| message += "#{@@list_prefix} #{v.gsub(/,/,"\n")}" }
    message += @@list_select_ed.gsub(/field/, field)
    # p message
    message
  end

  def self.sm_list( operation, operands, workitem )
    message = ''
    operands.split(/,/).each do |field|
      value = workitem.fields[ field ] || ''
      value = delete_reply_qoutations( value ) || ''
      message += @@list_select_st.gsub(/field/, field)
      value.each { |v| message += "#{@@list_prefix} #{v.gsub(/,/,"\n")}" }
      message += @@list_select_ed.gsub(/field/, field)
    end
    message
  end

  def self.sm_list_pair( operation, operands, workitem )
    message = Hash.new('')
    operands.split(/,/).each do |target|
      value = workitem.fields[ target ]
      next unless value
      value.split(@@separator).each_with_index do |v,idx|
        next unless v && v.size > 0
        message[ idx ] += "#{v} \n"
      end
    end
    message.values.join("\n#{'~'*20}\n")
  end

end
