
require 'yaml'
require 'openwfe/extras/participants/ar_participants'

class MailProcessRelation < ActiveRecord::Base
  include OpenWFE::Extras

  @@underline = [0x1B].pack("c*") + "[1;4;35m"
  @@normal = [0x1B].pack("c*") + "[0m"

  def self.delete_old_store( workitem )
    log_file = open('log/aritems.log','a+') unless log_file
    store = find_by_name( workitem.fei )
    if store
      ar = ArWorkitem.find_by_fei( store.item )
      if ar
        ar.destroy
        log_file.puts "# mailitem delete old ar #{ar.id}\n -- #{workitem.fei}"
      else
        log_file.puts "# mailitem no found ar:\n -- #{workitem.fei}"
      end
    else
      log_file.puts "# mailitem no found store:\n -- #{workitem.fei}"
    end
    log_file.close
    return store
  end

  def self.store_workitem( workitem, message='first time' )
    log_file = open('log/aritems.log','a+') unless log_file
    name = workitem.fei
    store = delete_old_store( workitem )
    ar = ArWorkitem.from_owfe_workitem( workitem )
    log_file.puts "\ncreate: ar #{ar.id} for [#{message}]\n -- #{name}"
    store = MailItem.new unless store
    store.name = name
    store.item = ar.fei
    store.save!
    log_file.puts "\ncreate: mi #{store.id} -- ar #{ar.id} [#{message}]"
    log_file.close
    return store
  end

  def self.get_workitem( id_or_fei, destroy='', from='listener' )
    log_file = open('log/aritems.log','a+') unless log_file
    id_or_fei = id_or_fei.to_s
    _id = (/\d+/ =~ id_or_fei)? find_by_id( id_or_fei ) : find_by_name( id_or_fei )
    log_file.puts "can not get ar.id for #{id_or_fei}" unless _id
    return unless _id
    ar = ArWorkitem.find_by_fei( _id.item )
    log_file.puts "can not get ar for #{id_or_fei}" unless ar
    return unless ar
    workitem = ar.to_owfe_workitem if ar
    if destroy == 'delete'
      ar.destroy
      _id.destroy 
      log_file.puts "from:#{from} delete ar #{ar.id} && mi #{id_or_fei}"
    end
    log_file.close
    return workitem
  end

end
