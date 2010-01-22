namespace :mediaclue do
  namespace :maintenance do
    
    desc 'Entfernt ungebrauchte Tags'
    task :remove_unused_tags => :environment do
      unused_tags = Tag.find(:all, :include => [:taggings], :conditions => 'taggings.id IS NULL')
      
      for unused_tag in unused_tags
        unused_tag.destroy
        puts "Tag #{unused_tag.name} gelöscht."
      end
    end
    
    desc 'Erzeugt alle Vorschauen neu'
    task :recreate_previews => :environment do
      Medium.all.each do |medium|
        puts "Erzeuge nebenläufig Vorschauen für Medium #{medium.id}"
        medium.recreate_previews
      end
    end
  end
end