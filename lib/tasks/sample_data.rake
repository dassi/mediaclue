namespace :mediaclue do
  namespace :sample_data do
    desc 'Lädt einen Test-Admin in die DB'
    task :load_admin => :environment do
      admins_group = UserGroup.find_or_create_by_full_name('Administratoren')
      puts 'Gruppe Administratoren erstellt'
      admins_group.save!

      user = User.find_or_initialize_by_login('admin')
      user.attributes = {:full_name => 'Administrator', :password => 'test', :password_confirmation => 'test'}
      user.save!
      puts 'admin mit Passwort test erstellt'
      
      admins_group.users << user
    end

    desc 'Lädt einen Test-User in die DB'
    task :load_user => :environment do
      users_group = UserGroup.find_or_create_by_full_name('Normalbenutzer')
      puts 'Gruppe Normalbenutzer erstellt'
      users_group.save!

      user = User.find_or_initialize_by_login('user')
      user.attributes = {:full_name => 'Normal-Benutzer', :password => 'test', :password_confirmation => 'test'}
      user.save!
      puts 'user mit Passwort test erstellt'
      
      users_group.users << user
    end
  end
end