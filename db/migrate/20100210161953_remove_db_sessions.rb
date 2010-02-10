class RemoveDbSessions < ActiveRecord::Migration
  def self.up
    drop_table :sessions
  end

  def self.down
    create_table "sessions", :force => true do |t|
      t.string   "session_id", :default => "", :null => false
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
  end
end
