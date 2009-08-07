class CreateMailItems < ActiveRecord::Migration
  def self.up
    create_table :mail_items do |t|
      t.string :name
      t.string :item

      t.timestamps
    end
  end

  def self.down
    drop_table :mail_items
  end
end
