
require 'google_spreadsheet'

class SMSpreadsheet

  @@config = 'config/config.yml'
  @@spreadSheet = nil
  @@spreadSheet_contents = nil

  def self.set_config_file( config_file )
    @@config = config_file
  end
 
  def self.get_columns_from_spreadsheet( sheet_name, field_name )
    fields = get_fields_from_spreadsheet( sheet_name )
    result = fields.collect { |info| info[:contents] if info[:title] == field_name }
    result.compact! if result
    # puts "get_columns_from_spreadsheet: #{sheet_name}, #{field_name}, #{result}"
    return result
  end

  def self.get_smartmail_participants_information( sheet_name=nil, field_name=nil )
    sheet_name = 'smartmail_workers'
    worker_names_fields = Kconv.toutf8('仕事依頼先')
    worker_email_fields = Kconv.toutf8('依頼先メール')
    names = get_columns_from_spreadsheet( sheet_name, worker_names_fields )
    names.each {|it| it.gsub!(/\s|&nbsp;|　/,'')}
    emails = get_columns_from_spreadsheet( sheet_name, worker_email_fields )
    emails.each {|it| it.gsub!(/\s|&nbsp;|　/,'')}
    result = [ names, emails ].transpose
  end

  def self.get_flow_description_from_spreadsheet( flow_name )
    # TODO: remove dependency with constent varaiables
    sheet_name, description_title, flow_name_title = 
    "smartmail_flows", Kconv.toutf8('フロー説明'), Kconv.toutf8('ワークフロー名')
    fields = get_fields_from_spreadsheet( sheet_name )
    title_f = fields.find {|data| data[:title] == flow_name_title && data[:contents] == flow_name}
    desc_field = fields.find {|data| data[:row] == title_f[:row] && data[:column] == title_f[:column]+1 }
    result = desc_field[:contents]
    return result
  end

  def self.get_stepname_from_spreadsheet( flow_name, step_name_short )
    # TODO: remove dependency with constent varaiables
    sheet_name, short_title, stepname = 
    flow_name+"_steps", Kconv.toutf8('ステップ略称'), Kconv.toutf8('ステップ説明')
    fields = get_fields_from_spreadsheet( sheet_name )
    title_f = fields.find {|data| data[:title] == short_title && data[:contents] == "\{sm_step_short:#{step_name_short}\}"}
    # puts "get_stepname_from_spreadsheet: flow:#{flow_name} title:#{title_f}"
    return unless title_f
    desc_field = fields.find {|data| data[:row] == title_f[:row] && data[:column] == title_f[:column]-1 }
    result = desc_field[:contents]
    return result
  end

  def self.get_fields_from_spreadsheet( sheet_name )
    return 'no sheet_name given.' unless sheet_name
    # puts "create spreadsheet cache for #{sheet_name}" unless @@spreadSheet_contents
    @@spreadSheet_contents = Hash.new unless @@spreadSheet_contents
    result = @@spreadSheet_contents[sheet_name]
    # puts "use spreadsheet cache for #{sheet_name} result:#{result.size}" if result
    # p "result: #{result.inspect}" if result
    return Marshal.load(Marshal.dump(result)) if result
    result = Array.new
    get_spreadsheet until @@spreadSheet
    # p @@spreadSheet.worksheets.collect {|ws| ws.title}.join(' , ')
    worksheet = get_worksheet( sheet_name ) until worksheet
    # puts "#{sheet_name}, use sheets: #{worksheet}"
    worksheet_data = worksheet.rows.dup
    # puts worksheet_data
    worksheet_title = worksheet_data.shift
    worksheet_data.each_with_index do |info, row_number|
      # puts "idx:#{row_number}, info:#{info}"
      worksheet_title.each_index do |column_number|
        str = Kconv.toutf8(worksheet_title[column_number])
        field = { 
          :row => row_number, 
          :column => column_number, 
          :title => str, 
          :contents => info[column_number] 
        }
        result << field
      end
    end
    # result.each {|res| res.each_pair { |k,v| puts "#{k} --> #{v}" } }
    @@spreadSheet_contents[sheet_name] = (result.size>0)? result : nil
    result
  end

  protected

  def self.get_worksheet( sheet_name, sleep_time=30, times=0 )
    begin
      worksheet = @@spreadSheet.worksheets.find { |ws| ws.title == sheet_name }
      # p worksheet
      return worksheet
    rescue Exception => e
      times += 1
      puts "get_worksheet#{sheet_name}[times:#{times}]: error #{e.message}"
      sleep sleep_time * times
      return get_worksheet( sheet_name, sleep_time, times )
    end
  end

  def self.get_settings()
    # p "get settings from: #{config_file}"
    settings = YAML.load_file(@@config)
    settings
  end

  def self.get_spreadsheet()
    settings = get_settings
    params = settings["smartmail"]
    username = params["user_name"]
    password = params["user_password"]
    spreadsheet_key = params["spreadsheet_key"]
    session = GoogleSpreadsheet.login( username, password )
    @@spreadSheet = session.spreadsheet_by_key( spreadsheet_key )
    # puts "get_spreadsheet #{@@spreadSheet}"
    sleep 3 unless @@spreadSheet
  end

end
