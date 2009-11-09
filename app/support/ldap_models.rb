# ActiveLdap Hilfsklasse
class LdapGroup < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'cn',
               :prefix => LDAP_GROUPS_DN_PREFIX,
               :classes => ['top', 'posixGroup']

  has_many :members, :wrap => "memberUid", :class => 'LdapUser', :primary_key => 'uid'
end

# ActiveLdap Hilfsklasse
class LdapUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => LDAP_USERNAME_ATTRIBUTE,
               :prefix => LDAP_USERS_DN_PREFIX,
               :classes => ['top', 'posixAccount']
             
  belongs_to :groups, :class => 'LdapGroup', :many => 'memberUid', :foreign_key => 'uid'
end
