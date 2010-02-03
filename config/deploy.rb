# Mongrel-recipes einbinden
# require 'mongrel_cluster/recipes'
# require 'ferret_cap_tasks'

#
# Multistage aktivieren
#
set :stages, %w(preview main)
set :default_stage, 'preview'
set :use_sudo, false
set :deploy_to_base_path, "/Library/WebServer/Documents/mediendatenbank"
set :default_shell, 'bash'
require 'capistrano/ext/multistage'


#
# Konfigurationen
#
set :application, 'mediendatenbank'
# set :rails_env, 'production'
set :use_sudo, false
set :user, 'mindclue'
set :user_group, 'staff'

# set :deploy_to, "/home/rails/#{application}"




# # set :shared_path, "#{deploy_to}/shared"
# set :repository,  "https://mindclue.dyndns.org/svn/mediaclue/branches/demo"
# # set :local_repository, "svn://mindclue-main/hopro/#{application}/trunk"
# set :deploy_via, :remote_cache
# 
# set :scm_username, 'nine'
# set :scm_password, 'n1n3'
# set :scm_prefer_prompt, false
# set :scm_auth_cache, true

# Wir nehmen per Default die Ruby Enterprise Variante, deshalb Pfad umbiegen:
# shell_environment = {'PATH' => '/opt/ruby-enterprise/bin:$PATH'}
# 'RUBYLIB' => '/usr/local/lib/ruby1.8.6/site_ruby/1.8:/usr/local/lib/ruby1.8.6/site_ruby/1.8/i486-linux:/usr/local/lib/ruby1.8.6/site_ruby/1.8/i386-linux:/usr/local/lib/ruby1.8.6/site_ruby'}
# set :default_environment, shell_environment


#
# Servers
#

# Via mindclue gateway, weil die KSHP die Firewall dafür konfiguriert hat. Falls ein Deployment ausserhalb mindclue nötig sein sollte.

# Problem beim Gatewy, weil die Passwort-Abfrage von capistrano nur einmal kommt. Das geht nur bei Zertifikats-Login ohne Passwortabfrage.
# siehe http://dev.rubyonrails.org/ticket/10533
# gateway_user = ENV['USER'] || 'nobody'
# set :gateway, "#{gateway_user}@mindclue.nine.ch"

# set :gateway, "mindclue@mindclue1.nine.ch"
# server = 'mdb.kshp.ch'
server = '212.117.123.187'

role :app, server
role :web, server
role :db,  server, :primary => true


#
# Helpers
#

def ferret_start
  run "cd #{current_path}; script/ferret_server -e production start"
end

def ferret_stop
  run "cd #{current_path}; script/ferret_server -e production stop; exit 0" # exit 0, weil wir bei einem Fehler nicht capistrano unterbrechen wollen
end

def ferret_restart
  ferret_stop
  ferret_start
end

def install_launchd_scripts
  
  # launchd_script_source = "#{release_path}/maintenance/#{stage}/launchd/ch.kshp.mdb.#{stage}.ldap_sync.plist"
  # launchd_script_target = "/Library/LaunchDaemons/ch.kshp.mdb.#{stage}.ldap_sync.plist"

  launchd_script_source = "#{release_path}/maintenance/#{stage}/launchd/*"
  launchd_script_target = "/Library/LaunchDaemons/"

  # launchd-Files kopieren und mit den richtigen Rechten versehen
  sudo "cp #{launchd_script_source} #{launchd_script_target}"
  run "chmod 644 #{launchd_script_target}ch.kshp.mdb.*"
  sudo "chown root:wheel #{launchd_script_target}ch.kshp.mdb.*"
  
  # Skripte neu laden
  sudo "launchctl unload #{launchd_script_target}ch.kshp.mdb.*"
  sudo "launchctl load #{launchd_script_target}ch.kshp.mdb.*"
  
end


#
# Tasks
#

# Hook nach dem Code update: Erstellt die softlinks zu Konfigurations-Files und anderen
after 'deploy:update_code' do
  run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{deploy_to}/shared/config/ferret_server.yml #{release_path}/config/ferret_server.yml"
  run "ln -nfs #{deploy_to}/shared/config/ldap.yml #{release_path}/config/ldap.yml"

  # Standort der Medien symlinken
  run "ln -nfs #{deploy_to}/shared/media_storage #{release_path}/media_storage"
end

# before 'deploy:restart' do
#   run "cd #{current_path}; rake kshp:ferret:ensure_index"
# end

# Tasks für die Applikation, im Namespace KSHP
namespace :kshp do

  desc 'Erstellt den Suchindex neu'
  task :rebuild_search_index do
    ferret_rebuild_index
  end

end



# Passenger-Applikationen auf deren Art und Weise restarten.
namespace :deploy do
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end


desc 'Dumps the production database to db/production_data.sql on the remote server'
task :remote_db_dump, :roles => :db, :only => { :primary => true } do
  run "cd #{current_path} && " +
    "rake RAILS_ENV=#{rails_env} db:database_dump --trace" 
end

desc 'Downloads db/production_data.sql from the remote production environment to your local machine'
task :remote_db_download, :roles => :db, :only => { :primary => true } do  
  execute_on_servers(options) do |servers|
    self.sessions[servers.first].sftp.connect do |tsftp|
      tsftp.get_file "#{deploy_to}/#{current_dir}/db/production_data.sql", "db/production_data.sql" 
    end
  end
end

desc 'Cleans up data dump file'
task :remote_db_cleanup, :roles => :db, :only => { :primary => true } do  
  delete "#{current_path}/db/production_data.sql" 
end 

desc 'Dumps, downloads and then cleans up the production data dump'
task :remote_db_runner do
  remote_db_dump
  remote_db_download
  remote_db_cleanup
end
