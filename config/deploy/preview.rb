# MAIN-specific deployment configuration
# please put general deployment config in config/deploy.rb
                                                      
# set :application, "mediendatenbank"

set :repository, "file:///Users/dassi/code/ruby/rails/mediaclue"
set :scm, :git

set :branch, 'HEAD'

set :deploy_via, :copy
set :copy_cache, true
set :copy_exclude, ['.git', 'tmp', 'log']


set :deploy_to, "#{deploy_to_base_path}/preview"

set :rails_env, 'production'

# after 'deploy:update_code' do
#   install_launchd_scripts
# end



before 'deploy:restart' do
  ferret_stop
  run "cd #{current_path}; rake kshp:ferret:ensure_index"  
  ferret_start
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