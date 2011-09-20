# require 'net/ldap'
# require 'active_ldap'

namespace :mediaclue do
  namespace :ldap do

    desc "Importiert die User und Gruppen aus dem LDAP-Server"
    task :import => :environment do

      raise 'Sie müssen die LDAP-Funktionen einschalten, um diese Aktion auszuführen' if not FEATURE_LDAP_AUTHENTICATION
      
      # OPTIMIZE: Im LDAP gelöschte User auch hier löschen

      # Alle Gruppen importieren
      LDAP_IMPORTED_USER_GROUPS.each do |group_uid|
        ldap_group = LdapGroup.find(group_uid)

        if ldap_group

          user_group = UserGroup.find_or_initialize_by_uid(group_uid)
          user_group.full_name = ldap_group.display_name

          if user_group.new_record?
            puts "Gruppe neu erstellt: #{user_group.full_name}"
          else
            puts "Gruppe aktualisiert: #{user_group.full_name}"

            # Gruppenzuordnungen für diese Gruppe erst alle löschen (werden dann wieder erstellt, so können Neuzuordnungen synchronisiert werden)
            UserGroupMembership.delete_all(:user_group_id => user_group.id)
          end

          if user_group.save

            # Für alle Mitglieder in dieser Gruppe
            ldap_group.members.each do |ldap_user|
              # user ohne UID gleich überspringen
              if ldap_user.uid.blank?
                puts "Fehler: LdapUser ohne UID! #{ldap_user.inspect}" 
                next
              end

              user = User.find_or_initialize_by_login(ldap_user.uid)
              user.full_name = ldap_user.display_name

              if ldap_user.mail
                email_from_ldap = ldap_user.mail.to_a.first
                user.email = email_from_ldap if email_from_ldap.present?
              end

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
      end      
    end
  end
end