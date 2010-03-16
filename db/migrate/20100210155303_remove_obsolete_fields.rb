class RemoveObsoleteFields < ActiveRecord::Migration
  def self.up
    remove_column :users, :is_group
    remove_column :users, :ldap_uid rescue nil
    remove_column :user_groups, :ldap_uid rescue nil
  end

  def self.down
    add_column :users, :is_group, :boolean
    add_column :users, :ldap_uid, :string
    add_column :user_groups, :ldap_uid, :string
  end
end
