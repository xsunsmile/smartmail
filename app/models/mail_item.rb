
require 'yaml'
require 'openwfe/extras/participants/ar_participants'

class MailItem < ActiveRecord::Base
  include OpenWFE::Extras

  @@underline = [0x1B].pack("c*") + "[1;4;35m"
  @@normal = [0x1B].pack("c*") + "[0m\n"

  def self.store_workitem( workitem )
    # name = YAML.dump( workitem.fei )
    name = workitem.fei
    puts "#{@@underline}find workitem:#{@@normal} for fei: #{name}"
    store = find_by_name( name ) || MailItem.new
    puts "#{@@underline}find store:#{@@normal} for store: #{store}"
    if store.item
      ar = ArWorkitem.find_by_id( store.item )
      puts "#{@@underline}find ar:#{@@normal} for ar: #{ar}"
      ar.destroy if ar
    end
    ar = ArWorkitem.from_owfe_workitem( workitem ) rescue 'can not create ar_workitem'
    puts "#{@@underline}found ar:#{@@normal} for ar: #{ar}"
    store.name = name
    store.item = ar.id
    store.save!
    puts "#{@@underline}store workitem:#{@@normal} #{name}"
    return store
  end

  def self.get_workitem( id_or_fei, destroy='' )
    _id = (/\d+/ =~ id_or_fei)? find_by_id( id_or_fei ) : find_by_name( id_or_fei )
    return unless _id
    ar = ArWorkitem.find_by_id( _id.item )
    return unless ar
    workitem = ar.to_owfe_workitem if ar
    if destroy == 'delete'
      ar.destroy && _id.destroy
    end
    return workitem
  end

end
