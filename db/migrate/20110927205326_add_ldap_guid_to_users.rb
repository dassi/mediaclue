class AddLdapGuidToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :ldap_guid, :string
  end

  def self.down
    remove_column :users, :ldap_guid
  end
end
