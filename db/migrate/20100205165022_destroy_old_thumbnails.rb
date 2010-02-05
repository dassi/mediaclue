class DestroyOldThumbnails < ActiveRecord::Migration
  def self.up

    Image.destroy_all('parent_id IS NOT NULL')
    
    # # Alle Thumbnails kopieren in ImageThumbnail-Objekte
    # ImageThumbnail.transaction do
    #   for thumbnail in thumbnails
    #     ImageThumbnail.create!(thumbnail.attributes)
    #     thumbnail.destroy
    #   end
    # end
    
    begin
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
