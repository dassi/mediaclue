class DestroyOldThumbnails < ActiveRecord::Migration
  def self.up

    begin
      # Image.destroy_all('parent_id IS NOT NULL')

      Image.find(:all, :conditions => 'parent_id IS NOT NULL').each do |image|
        thumbnail_filepath = File.join(RAILS_ROOT, MEDIA_STORAGE_PATH_PREFIX, ("%08d" % image.parent_id).scan(/..../) + [image.filename])

        begin
          puts "Deleting file #{thumbnail_filepath}..."

          FileUtils.rm(thumbnail_filepath)
          puts "...deleted"
          
          # remove directory also if it is now empty
          Dir.rmdir(File.dirname(thumbnail_filepath)) if (Dir.entries(File.dirname(thumbnail_filepath))-['.','..']).empty?
        rescue SystemCallError
          puts "Exception destroying  #{thumbnail_filepath}: [#{$!.class.name}] #{$1.to_s}"
        end
        
        # image.destroy
        
      end

      Image.delete_all('parent_id IS NOT NULL')
      
      remove_column :media, :thumbnail
      remove_column :media, :parent_id
    rescue
      # Ignorieren falls schon entfernt
    end

  end

  def self.down
    add_column :media, :parent_id, :integer
    add_column :media, :thumbnail, :string
  end
end
