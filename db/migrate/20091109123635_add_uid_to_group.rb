class AddUidToGroup < ActiveRecord::Migration
  def self.up
    add_column :user_groups, :uid, :string
  end

  def self.down
    remove_column :user_groups, :uid
  end
end
