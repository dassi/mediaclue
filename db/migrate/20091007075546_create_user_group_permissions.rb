class CreateUserGroupPermissions < ActiveRecord::Migration
  def self.up
    create_table :user_group_permissions do |t|
      t.belongs_to :user_group
      t.belongs_to :object, :polymorphic => true
      t.boolean :read, :default => false 
      t.boolean :write, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :user_group_permissions
  end
end
