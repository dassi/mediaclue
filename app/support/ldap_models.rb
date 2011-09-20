# ActiveLdap Hilfsklasse
class LdapGroup < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'cn',
               :prefix => LDAP_GROUPS_DN_PREFIX,
               :classes => ['top', 'posixGroup']

  has_many :members, :wrap => "memberUid", :class => 'LdapUser', :primary_key => 'uid'
  
  def display_name
    base_name = self.cn.titlecase
    additional_name = LDAP_ADDITIONAL_GROUP_NAME_ATTRIBUTES.collect{ |attribute| self[attribute] }.find{ |value| not value.blank? }

    if additional_name and (base_name.downcase != additional_name.downcase)
      "#{base_name} (#{additional_name})"
    else
      base_name
    end
  end
  
end

# ActiveLdap Hilfsklasse
class LdapUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => LDAP_USERNAME_ATTRIBUTE,
               :prefix => LDAP_USERS_DN_PREFIX,
               :classes => ['top', 'posixAccount']
             
  belongs_to :groups, :class => 'LdapGroup', :many => 'memberUid', :foreign_key => 'uid'
  
  def display_name
    self.cn
  end
  
  def email
    if self.has_attribute?(:mail)
      email_from_ldap = self.mail.to_a.first
      return email_from_ldap if email_from_ldap.present?
    end

    nil
  end
  
end
