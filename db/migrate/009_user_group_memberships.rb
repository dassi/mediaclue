class UserGroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :user_group_memberships do |t|
      t.integer :user_id
      t.integer :user_group_id
#      t.boolean :is_primary_group
      t.timestamps      
    end
  end

  def self.down
    drop_table :user_group_memberships 
  end
end
