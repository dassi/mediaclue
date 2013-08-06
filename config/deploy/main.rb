# MAIN-specific deployment configuration
# please put general deployment config in config/deploy.rb

# Ein erneutes "Ja" soll der Benutzer angeben, wenn er main deployt
confirmation = Capistrano::CLI.ui.ask "Sie deployen die Hauptinstanz der Mediendatenbank KSHP. Sind Sie sicher, dass Sie das wollen? Um weiterzufahren, 'Ja' eintippen:"
exit(-1) unless confirmation == 'Ja'
                                                      
# set :application, "mediendatenbank"

set :scm, :git
set :repository, 'gitolite@mindclue.dyndns.org:kshp/mediaclue.git'
set :local_repository, 'gitolite@mindclue-file:kshp/mediaclue.git'
set :branch, 'master'
#set :remote, 'origin'
set :deploy_via, :remote_cache
# set :deploy_via, :export
# set :copy_exclude, ['.git', 'tmp', 'log']


set :deploy_to, "#{deploy_to_base_path}/main"
# brauchts nicht mehr, wegen Passenger: set :mongrel_conf, "#{deploy_to}/current/config/mongrel_cluster.yml" 

# set :default_environment, {'RAILS_ENV' => 'production'}
set :rails_env, 'production'

# Nur die MAIN-Stage darf den produktiven Medienordner benützen!
after 'deploy:update_code' do
  # Standort der Medien symlinken
  
  # später, wenn produktiv: run "ln -nfs /Volumes/SharedFolders/mediendatenbank/media_storage #{release_path}/media_storage"
  run "ln -nfs #{deploy_to}/shared/media_storage #{release_path}/media_storage"
end

# after 'deploy:update_code' do
#   install_launchd_scripts
# end

# before 'deploy:restart' do
#   ferret_restart
# end
# 
# after 'deploy:stop' do
#   ferret_stop
# end
# 
# before 'deploy:start' do
#   ferret_start
# end

after 'deploy:update_code' do
  # Ferret Index wird nur einmal geführt für alle relases, da es sehr lange dauert bei produktiven Daten ihn zu erzeugen
  run "ln -nfs #{deploy_to}/shared/ferret_index #{release_path}/index"
end

# install_launchd_scripts sollte sehr spät erfolgen, da es mitunter auch ferret neu starten würde.
# Es ergäbe sonst race conditions, wonach ferret dann zweimal laufen würde!
after 'deploy' do
  install_launchd_scripts
end