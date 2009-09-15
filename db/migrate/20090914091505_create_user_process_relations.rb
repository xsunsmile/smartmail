class CreateUserProcessRelations < ActiveRecord::Migration
  def self.up
    create_table :user_process_relations do |t|
      t.integer :user_id
      t.integer :wfid

      t.timestamps
    end
  end

  def self.down
    drop_table :user_process_relations
  end
end
