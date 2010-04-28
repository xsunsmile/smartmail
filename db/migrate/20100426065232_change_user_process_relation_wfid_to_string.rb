class ChangeUserProcessRelationWfidToString < ActiveRecord::Migration
  def self.up
    change_column :user_process_relations, :wfid, :string
  end

  def self.down
    change_column :user_process_relations, :wfid, :integer
  end
end
