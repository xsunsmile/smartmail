
require 'yaml'
require 'openwfe/extras/participants/ar_participants'

class MailItem < ActiveRecord::Base
  include OpenWFE::Extras

  @@underline = [0x1B].pack("c*") + "[1;4;35m"
  @@normal = [0x1B].pack("c*") + "[0m\n"

  def self.store_workitem( workitem )
    name = YAML.dump( workitem.fei )
    store = find_by_name( name ) || MailItem.new
    if store.item
      # puts "#{@@underline}find workitem:#{@@normal} #{name}"
      ar = ArWorkitem.find_by_id( store.item )
      ar.destroy if ar
    end
    ar = ArWorkitem.from_owfe_workitem( workitem )
    store.name = name
    store.item = ar.id
    store.save!
    # puts "#{@@underline}store workitem:#{@@normal} #{name}"
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
