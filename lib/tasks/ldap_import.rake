# require 'net/ldap'
# require 'active_ldap'

namespace :mediaclue do
  namespace :ldap do

    def import_ldap_group(ldap_group)                    
      group_uid = ldap_group.cn
      
      user_group = UserGroup.find_or_initialize_by_uid(group_uid)
      user_group.full_name = ldap_group.display_name
      user_group.can_upload = LDAP_USER_GROUPS_WITH_UPLOAD_FEATURE.include?(group_uid)

      if user_group.new_record?
        puts "Gruppe neu erstellt: #{user_group.full_name}"
      else
        puts "Gruppe aktualisiert: #{user_group.full_name}"

        # Gruppenzuordnungen für diese Gruppe erst alle löschen (werden dann wieder erstellt, so können Neuzuordnungen synchronisiert werden)
        UserGroupMembership.delete_all(:user_group_id => user_group.id)
      end

      if user_group.save

        # Für alle Mitglieder in dieser Gruppe und Subgruppen
        ldap_group.all_members.each do |ldap_user|
          # user ohne UID gleich überspringen
          if ldap_user.uid.blank?
            puts "Fehler: LdapUser ohne UID! #{ldap_user.inspect}" 
            next
          end

          user = User.find_by_ldap_guid(ldap_user.apple_guid) || User.find_or_initialize_by_login(ldap_user.uid)

          user.login = ldap_user.uid
          user.ldap_guid = ldap_user.apple_guid
          user.full_name = ldap_user.display_name
          user.email = ldap_user.email

          if user.new_record?
            puts "Benutzer neu erstellt: #{user.full_name}"
          else
            puts "Benutzer aktualisiert: #{user.full_name}"
          end

          if user.save
            # User an Gruppe befügen
            user_group.users << user
          else
            puts "Benutzer nicht valid: #{user.full_name}, mit Fehler: " + user.errors.full_messages.join(', ')
          end

        end
      else
        puts "Gruppe nicht valid: #{user_group.full_name}, mit Fehler: " + user_group.errors.full_messages.join(', ')
      end
      
    end


    desc "Importiert die User und Gruppen aus dem LDAP-Server"
    task :import => :environment do

      raise 'Sie müssen die LDAP-Funktionen einschalten, um diese Aktion auszuführen' if not FEATURE_LDAP_AUTHENTICATION
      
      # OPTIMIZE: Im LDAP gelöschte User auch hier löschen

      # Alle Gruppen importieren
      LDAP_IMPORTED_USER_GROUPS.each do |group_uid|
        ldap_group = LdapGroup.find(group_uid)

        if ldap_group
          import_ldap_group(ldap_group)
        end
      end
      
      # Alle regular expression Gruppen importieren
      all_ldap_groups = LdapGroup.find(:all)
      LDAP_IMPORTED_USER_GROUPS_REGEXP.each do | group_pattern |
        ldap_groups = all_ldap_groups.select { |ldap_group| ldap_group.cn =~ group_pattern }

        ldap_groups.each do | ldap_group |
          import_ldap_group(ldap_group)
        end
      end
      
    end
  end
end