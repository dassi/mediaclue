class RemoveRoles < ActiveRecord::Migration
  def self.up
    # Migrationsreihenfolge geändert
    # drop_table :roles
    # drop_table :roles_users
    # drop_table :roles_user_groups
  end

  def self.down
    # Migrationsreihenfolge geändert
    # create_table "roles_user_groups", :id => false, :force => true do |t|
    #   t.integer  "user_group_id"
    #   t.integer  "role_id"
    #   t.datetime "created_at"
    #   t.datetime "updated_at"
    # end
    # 
    # create_table "roles_users", :id => false, :force => true do |t|
    #   t.integer  "user_id"
    #   t.integer  "role_id"
    #   t.datetime "created_at"
    #   t.datetime "updated_at"
    # end
    # 
    # create_table "roles", :force => true do |t|
    #   t.string   "name",              :limit => 40
    #   t.string   "authorizable_type", :limit => 30
    #   t.integer  "authorizable_id"
    #   t.datetime "created_at"
    #   t.datetime "updated_at"
    # end
    
  end
end
