class CreateGroupPermissions < ActiveRecord::Migration
  def self.up
    create_table :group_permissions do |t|
      t.belongs_to :group
      t.belongs_to :medium
      t.boolean :read, :default => false 
      t.boolean :write, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :group_permissions
  end
end
