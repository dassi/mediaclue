namespace :mediaclue do
  namespace :sample_data do
    desc 'Lädt einen Test-Admin in die DB'
    task :load_admin => :environment do
      User.create!(:login => 'admin', :full_name => 'Administrator', :password => 'test', :password_confirmation => 'test')
      puts 'admin mit Passwort test erstellt'
    end

    desc 'Lädt einen Test-User in die DB'
    task :load_user => :environment do
      User.create!(:login => 'user', :full_name => 'Normal-Benutzer', :password => 'test', :password_confirmation => 'test')
      puts 'user mit Passwort test erstellt'
    end
  end
end