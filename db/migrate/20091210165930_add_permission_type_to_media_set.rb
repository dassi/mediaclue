class AddPermissionTypeToMediaSet < ActiveRecord::Migration
  def self.up
    add_column :media_sets, :permission_type, :string, :default => 'owner'
  end

  def self.down
    remove_column :media_sets, :permission_type
  end
end
