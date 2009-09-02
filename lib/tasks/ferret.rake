namespace :app do
  namespace :ferret do
    desc 'Stellt sicher, dass der Suchindex vorhanden ist'
    task :ensure_index => :environment do
      MediaSet.aaf_index.ensure_index_exists
      Medium.aaf_index.ensure_index_exists
    end
    
    desc 'Berechnet den Index neu'
    task :rebuild_index => :environment do
      sh 'rm -drf index'
      MediaSet.aaf_index.ensure_index_exists
      Medium.aaf_index.ensure_index_exists
    end
    
  end
end