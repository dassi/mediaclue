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
          user_group.full_name = ldap_group.cn

          if user_group.new_record?
            puts "Gruppe neu erstellt: #{user_group.inspect}"
          else
            puts "Gruppe aktualisiert: #{user_group.inspect}"

            # Gruppenzuordnungen für diese Gruppe erst alle löschen (werden dann wieder erstellt, so können Neuzuordnungen synchronisiert werden)
            UserGroupMembership.delete_all(:user_group_id => user_group.id)
          end

          user_group.save!


          # Für alle Mitglieder in dieser Gruppe
          ldap_group.members.each do |ldap_user|
            # user ohne UID gleich überspringen
            raise "LdapUser ohne UID! #{ldap_user.inspect}" unless ldap_user.uid

            user = User.find_or_initialize_by_login(ldap_user.uid)
            user.full_name = ldap_user.cn

            if user.new_record?
              puts "Benutzer neu erstellt: #{user.inspect}"
            else
              puts "Benutzer aktualisiert: #{user.inspect}"
            end

            user.save!

            # User an Gruppe befügen
            user_group.users << user

          end
        end
      end      
    end
  end
end