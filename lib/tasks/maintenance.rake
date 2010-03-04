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
    
    desc 'Erzeugt nochmals alle Vorschauen neu'
    task :recreate_previews => :environment do
      Medium.all.each do |medium|
        puts "Erzeuge nebenläufig Vorschauen für Medium #{medium.id}"
        medium.recreate_previews
      end
    end

    desc 'Erzeugt alle Vorschauen, die noch nicht existieren'
    task :create_previews => :environment do
      Medium.all.each do |medium|
        if not medium.has_preview?
          puts "Erzeuge nebenläufig Vorschauen für Medium #{medium.id}"
          medium.recreate_previews
        end
      end
    end

    desc 'Importiert alle EXIF Meta-Daten neu, ohne zu überschreiben'
    task :initialize_meta_data => :environment do
      Medium.all.each do |medium|
        if medium.meta_data.nil? or medium.meta_data.empty?
          puts "Importiere EXIF für Medium #{medium.id}"
          medium.reread_meta_data
        else
          puts "Kein erneuter Import von EXIF für Medium #{medium.id}"
        end
      end
    end
  end
end