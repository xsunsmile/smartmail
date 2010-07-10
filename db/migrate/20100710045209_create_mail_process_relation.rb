class CreateMailProcessRelation < ActiveRecord::Migration
  def self.up
    create_table 'mail_process_relations', :force => true do |t|
      t.column :mail_body, :string
      t.column :fei, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table 'mail_process_relations'
  end
end
