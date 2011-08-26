class AddCanUploadToUserGroup < ActiveRecord::Migration
  def self.up
    add_column :user_groups, :can_upload, :boolean, :default => true
  end

  def self.down
    remove_column :user_groups, :can_upload
  end
end
