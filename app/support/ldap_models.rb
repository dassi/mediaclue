

class LdapModelBase < ActiveLdap::Base

  protected #######################################################################################
  
  def check(ldap_collection)
    ldap_collection.select{ |item| item.exists? }
  end

  public ##########################################################################################
  
  def display_name
    raise NotImplementedError
  end

  def apple_guid
    self['apple-generateduid']
  end
end


# ActiveLdap Hilfsklasse
class LdapGroup < LdapModelBase
  ldap_mapping :dn_attribute => 'cn',
               :prefix => LDAP_GROUPS_DN_PREFIX,
               :classes => ['top', 'posixGroup', 'apple-group', 'extensibleObject']

  # has_many :members, :wrap => "memberUid", :class => 'LdapUser', :primary_key => 'uid'

  has_many :unchecked_members, :wrap => 'apple-group-memberguid', :class => 'LdapUser', :primary_key => 'apple-generateduid'
  
  # Subgruppen
  has_many :unchecked_nested_groups, :wrap => 'apple-group-nestedgroup', :class => 'LdapGroup', :primary_key => 'apple-generateduid'

  # Obergruppen
  belongs_to :unchecked_parent_groups, :class => 'LdapGroup', :many => 'apple-group-nestedgroup', :primary_key => 'apple-generateduid'

  protected #######################################################################################
  
  # Liefert die direkten und indirekten Mitglieder dieser Gruppe
  def all_members_recursion(members_collection)
    # Eigene Mitglieder der Collection hinzufügen
    members_collection.concat(self.unchecked_members.to_a)
               
    # Rekursiv die Mitglieder zusammensammeln
    for group in self.nested_groups
      group.all_members_recursion(members_collection)
    end
  end
  

  public ##########################################################################################

  # Liefert die direkten und indirekten Mitglieder dieser Gruppe
  def all_unchecked_members
    the_members = []
    all_members_recursion(the_members)
    the_members.uniq
  end
  
  # Liefert die direkten und indirekten Mitglieder dieser Gruppe
  def all_members
    check(all_unchecked_members)
  end
  
  def members
    check(unchecked_members)
  end
  
  def nested_groups
    check(unchecked_nested_groups)
  end
  
  def parent_groups
    check(unchecked_parent_groups)
  end

  
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
class LdapUser < LdapModelBase
  ldap_mapping :dn_attribute => LDAP_USERNAME_ATTRIBUTE,
               :prefix => LDAP_USERS_DN_PREFIX,
               :classes => ['top', 'posixAccount', 'extensibleObject']
             
  # belongs_to :groups, :class => 'LdapGroup', :many => 'memberUid', :foreign_key => 'uid'

  belongs_to :unchecked_groups, :class => 'LdapGroup', :many => 'apple-group-memberguid', :primary_key => 'apple-generateduid'

  protected #######################################################################################
  
  public #########################################################################################

  def groups
    check(unchecked_groups)
  end

  
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
