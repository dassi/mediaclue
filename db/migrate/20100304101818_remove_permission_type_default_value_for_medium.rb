class RemovePermissionTypeDefaultValueForMedium < ActiveRecord::Migration
  def self.up
    change_column :media, :permission_type, :string, :default => nil
  end

  def self.down
    change_column :media, :permission_type, :string, :default => 'owner'
  end
end
