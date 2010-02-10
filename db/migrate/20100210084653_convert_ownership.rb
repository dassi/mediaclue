class ConvertOwnership < ActiveRecord::Migration
  def self.up
    self.is_owner_of_what MediaSet, :conditions => {:state => state.to_s}

    # Owner umschreiben von der alten roles Tabelle für alle Kollektionen
    for media_set in MediaSet.all
      sql = "SELECT roles_users.user_id FROM roles_users INNER JOIN roles ON roles_users.role_id=roles.id WHERE roles.authorizable_type = \"MediaSet\" AND roles.authorizable_id=#{media_set.id}"
      data = ActiveRecord::Base.connection.select_one(sql)
      if data
        media_set.owner_id = data['user_id']
        media_set.save!
      end
    end
    
    # Owner umschreiben von der alten roles Tabelle für alle Medien
    for medium in Medium.all
      sql = "SELECT roles_users.user_id FROM roles_users INNER JOIN roles ON roles_users.role_id=roles.id WHERE roles.authorizable_type = \"Medium\" AND roles.authorizable_id=#{medium.id}"
      data = ActiveRecord::Base.connection.select_one(sql)
      if data
        medium.owner_id = data['user_id']
        medium.save!
      end
    end
    
    begin
      drop_table :roles
      drop_table :roles_users
      drop_table :roles_user_groups
    rescue
      # nichts machen, sofern diese Tabellen gar nicht mehr existieren
    end
    
  end

  def self.down

    create_table "roles_user_groups", :id => false, :force => true do |t|
      t.integer  "user_group_id"
      t.integer  "role_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "roles_users", :id => false, :force => true do |t|
      t.integer  "user_id"
      t.integer  "role_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "roles", :force => true do |t|
      t.string   "name",              :limit => 40
      t.string   "authorizable_type", :limit => 30
      t.integer  "authorizable_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end
end
