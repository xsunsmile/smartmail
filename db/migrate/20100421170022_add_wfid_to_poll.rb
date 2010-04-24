class AddWfidToPoll < ActiveRecord::Migration
  def self.up
    add_column :polls, :wfid, :string
  end

  def self.down
    remove_column :polls, :wfid
  end
end
