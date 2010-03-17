class AddPermissionTypeToMedium < ActiveRecord::Migration
  def self.up
    add_column :media, :permission_type, :string, :default => DEFAULT_PERMISSION_TYPE
    remove_column :media, :is_public
  end

  def self.down
    add_column :media, :is_public, :boolean
    remove_column :media, :permission_type
  end
end
