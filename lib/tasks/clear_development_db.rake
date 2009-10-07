namespace :db do

desc "Löscht alle Daten der Models Medium, MediaSet, MediaSetMembership, Tag, Tagging, Role"
task :clear_models => :environment do
  [Medium, MediaSet, MediaSetMembership, Tag, Tagging].each do |model|
    model.destroy_all
  end
end

end