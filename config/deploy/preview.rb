# PREVIEW-specific deployment configuration
# please put general deployment config in config/deploy.rb
                                                      
# set :application, "mediendatenbank"

set :repository, "file:///Users/dassi/code/ruby/rails/mediaclue"
set :scm, :git

set :branch, 'HEAD'

set :deploy_via, :copy
set :copy_cache, true
set :copy_exclude, ['.git', 'tmp', 'log']


set :deploy_to, "#{deploy_to_base_path}/preview"

set :default_environment, {'RAILS_ENV' => 'production'}
set :rails_env, 'production'

# after 'deploy:update_code' do
#   install_launchd_scripts
# end


# Die PREVIEW-Stage darf den produktiven Medienordner nicht benützen! Verwendet einen Ordner im shared-Pfad
after 'deploy:update_code' do
  # Standort der Medien symlinken
  run "ln -nfs #{deploy_to}/shared/media_storage #{release_path}/media_storage"
end

# Standort der Medien symlinken
run "ln -nfs #{deploy_to}/shared/media_storage #{release_path}/media_storage"


before 'deploy:restart' do
  ferret_restart
  run "cd #{current_path}; rake mediaclue:ferret:ensure_index"  
end

after 'deploy:stop' do
  ferret_stop
end

before 'deploy:start' do
  ferret_start
end

# install_launchd_scripts sollte sehr spät erfolgen, da es mitunter auch ferret neu starten würde.
# Es ergäbe sonst race conditions, wonach ferret dann zweimal laufen würde!
after 'deploy' do
  install_launchd_scripts
end