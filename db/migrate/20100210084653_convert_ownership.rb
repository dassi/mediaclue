class ConvertOwnership < ActiveRecord::Migration
  def self.up

    # Owner umschreiben von der alten roles Tabelle für alle Kollektionen
    MediaSet.disable_ferret
    Medium.disable_ferret

    
    # Bitter nötig, sonst werden die neuen Felder von vorherigen Migrationen nicht sauber gespeichert
    ([MediaSet, Medium] + Medium.sub_classes).each do |klass|
      klass.reset_column_information
    end
    
    for media_set in MediaSet.all
      sql = "SELECT roles_users.user_id FROM roles_users INNER JOIN roles ON roles_users.role_id=roles.id WHERE roles.name=\"owner\" AND roles.authorizable_type = \"MediaSet\" AND roles.authorizable_id=#{media_set.id}"
      data = ActiveRecord::Base.connection.select_one(sql)
      if data
        media_set.owner_id = data['user_id'].to_i
        media_set.save_without_validation!
        puts "Zuweisung MediaSet #{media_set.id} zu Owner #{media_set.owner_id}"
      else
        puts "Keine Zuweisung für MediaSet #{media_set.id}"
      end
    end
    
    # Owner umschreiben von der alten roles Tabelle für alle Medien
    for medium in Medium.all
      sql = "SELECT roles_users.user_id FROM roles_users INNER JOIN roles ON roles_users.role_id=roles.id WHERE roles.name=\"owner\" AND roles.authorizable_type = \"Medium\" AND roles.authorizable_id=#{medium.id}"
      data = ActiveRecord::Base.connection.select_one(sql)
      if data
        medium.owner_id = data['user_id'].to_i
        medium.save_without_validation!
        puts "Zuweisung Medium #{medium.id} zu Owner #{medium.owner_id}"
      else
        puts "Keine Zuweisung für Medium #{medium.id}"
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
