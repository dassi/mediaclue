class AddOwnerToMedium < ActiveRecord::Migration
  def self.up
    add_column :media, :owner_id, :integer
    rename_column :media_sets, :user_id, :owner_id
  end

  def self.down
    rename_column :media_sets, :owner_id, :user_id
    remove_column :media, :owner_id
  end
end
