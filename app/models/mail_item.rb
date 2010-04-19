
require 'yaml'
require 'openwfe/extras/participants/ar_participants'

class MailItem < ActiveRecord::Base
  include OpenWFE::Extras

  @@underline = [0x1B].pack("c*") + "[1;4;35m"
  @@normal = [0x1B].pack("c*") + "[0m"

  def self.store_workitem( workitem )
    log_file = open('log/aritems.log','a+') unless log_file
    # name = YAML.dump( workitem.fei )
    name = workitem.fei
    log_file.puts "\n#{@@underline}find workitem:#{@@normal} for fei: #{name}"
    store = find_by_name( name ) 
    store = MailItem.new unless store
    log_file.puts "\n#{@@underline}find store:#{@@normal} for store: #{store}"
    if store.item
      ar = ArWorkitem.find_by_id( store.item )
      log_file.puts "\n#{@@underline}find ar:#{@@normal} for ar: #{ar}"
      ar.destroy if ar
      log_file.puts "delete old ar #{ar.id}" if ar
    end
    begin
      ar = ArWorkitem.from_owfe_workitem( workitem )
      if ar
        # log_file.puts "\n#{@@underline}found ar:#{@@normal} for ar: #{ar}"
        log_file.puts "\ncreate or found: #{store.id} -- #{ar.id}"
        store.name = name
        store.item = ar.id
        store.save!
      else
        log_file.puts "\n#{@@underline}Can not create ar for#{@@normal}: #{workitem}"
      end
    rescue => exception
      log_file.puts exception.inspect
    end
    log_file.puts "\n#{@@underline}store workitem:#{@@normal} #{name}"
    log_file.close
    return store
  end

  def self.get_workitem( id_or_fei, destroy='', from='listener' )
    log_file = open('log/aritems.log','a+') unless log_file
    _id = (/\d+/ =~ id_or_fei)? find_by_id( id_or_fei ) : find_by_name( id_or_fei )
    log_file.puts "can not get ar.id for #{id_or_fei}" unless _id
    return unless _id
    ar = ArWorkitem.find_by_id( _id.item )
    log_file.puts "can not get ar for #{id_or_fei}" unless ar
    return unless ar
    workitem = ar.to_owfe_workitem if ar
    if destroy == 'delete'
      log_file.puts "#{from} delete ar for #{id_or_fei} -- #{ar.id}"
      ar.destroy && _id.destroy
    end
    log_file.close
    return workitem
  end

end
