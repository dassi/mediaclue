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
  end
end